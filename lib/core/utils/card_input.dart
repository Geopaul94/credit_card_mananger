import 'package:flutter/services.dart';

/// Formats a card number as it is typed: digits only, grouped in blocks of
/// four ("4111 1111 1111 1111"), capped at 19 digits (ISO 7812 maximum).
class CardNumberInputFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.length > 19) digits = digits.substring(0, 19);

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();

    // Keep the caret after the same digit it followed before formatting.
    final rawCursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsBeforeCursor =
        newValue.text.substring(0, rawCursor).replaceAll(_nonDigits, '').length;
    if (digitsBeforeCursor > digits.length) digitsBeforeCursor = digits.length;
    final spacesBeforeCursor =
        digitsBeforeCursor == 0 ? 0 : (digitsBeforeCursor - 1) ~/ 4;
    final cursor =
        (digitsBeforeCursor + spacesBeforeCursor).clamp(0, text.length);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

/// Formats an expiry date as it is typed:
///  - digits only, rendered as MM/YY
///  - the slash appears the moment the second month digit is entered
///  - a leading 2-9 is auto-prefixed with 0 ("3" -> "03/")
///  - deleting works naturally (the slash is not re-inserted mid-backspace)
class ExpiryDateInputFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final isDeletion = newValue.text.length < oldValue.text.length;
    var digits = newValue.text.replaceAll(_nonDigits, '');

    // Typing "3" can only mean month 03; save the user a keystroke.
    if (digits.length == 1 && !isDeletion && int.parse(digits) > 1) {
      digits = '0$digits';
    }
    if (digits.length > 4) digits = digits.substring(0, 4);

    String text;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && !isDeletion) {
      // Slash appears immediately after the second digit is typed.
      text = '$digits/';
    } else {
      text = digits;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Luhn checksum (ISO 7812). Every genuine card number passes this; a failure
/// almost always means a typo. Used as a save-time warning, never a block.
bool luhnCheck(String digits) {
  if (digits.length < 12) return false;
  var sum = 0;
  var doubleIt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var d = digits.codeUnitAt(i) - 0x30;
    if (doubleIt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    doubleIt = !doubleIt;
  }
  return sum % 10 == 0;
}

/// Validates a card number, returning an exact, actionable message.
/// All world networks (credit, debit, forex, prepaid) use 12-19 digits.
String? validateCardNumber(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Enter the card number';
  if (digits.length < 12) {
    return 'Only ${digits.length} digits — card numbers have 12 to 19';
  }
  if (digits.length > 19) {
    return '${digits.length} digits is too long — cards have at most 19';
  }
  return null;
}

/// Validates an expiry date (MM/YY), returning an exact, actionable message.
/// Expired dates are allowed here (warned at save time); impossible dates
/// are blocked.
String? validateExpiry(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter the expiry date';
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v);
  if (match == null) return 'Enter expiry as MM/YY, e.g. 08/28';
  final month = int.parse(match.group(1)!);
  if (month < 1 || month > 12) {
    return 'Month $month doesn\'t exist — use 01 to 12';
  }
  final year = 2000 + int.parse(match.group(2)!);
  final maxYear = DateTime.now().year + 15;
  if (year > maxYear) {
    return 'Year 20${match.group(2)} looks wrong — cards are valid at most ~10 years';
  }
  return null;
}

/// Validates a security code. Storing one is optional, so an empty value is
/// accepted; anything typed must be the 3 digits printed on the signature
/// strip (4 on American Express).
String? validateCvv(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null; // optional — leaving it blank is fine
  if (digits.length < 3) {
    return 'Only ${digits.length} digit${digits.length == 1 ? '' : 's'} — a CVV has 3 (4 on Amex)';
  }
  if (digits.length > 4) return 'A CVV is at most 4 digits';
  return null;
}

/// True when a well-formed MM/YY date is already in the past. A card expires
/// at the END of its printed month.
bool isExpiredDate(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value.trim());
  if (match == null) return false;
  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  final now = DateTime.now();
  return year < now.year || (year == now.year && month < now.month);
}

/// Bank names that are acronyms, so they read correctly however they were
/// typed. Without this, someone entering "csb" gets "Csb" — title case is
/// right for words and wrong for initialisms.
const _bankAcronyms = <String>{
  'csb', 'sbi', 'hdfc', 'icici', 'idfc', 'idbi', 'rbl', 'pnb', 'bob',
  'iob', 'uco', 'kvb', 'tmb', 'dcb', 'hsbc', 'sib', 'au', 'ubi', 'obc',
  'boi', 'cub', 'esaf', 'nsdl', 'jk', 'sc',
};

/// Title-cases each word ("geo paulson" -> "Geo Paulson") while preserving
/// words the user typed fully capitalised, so bank acronyms survive
/// ("HDFC bank" -> "HDFC Bank"). Known bank initialisms are capitalised even
/// when typed in lower case ("csb jupiter" -> "CSB Jupiter").
String smartTitleCase(String input) {
  return input
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) {
        if (w.isEmpty) return w;
        final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(w);
        final isAllCaps = hasLetters && w == w.toUpperCase() && w.length > 1;
        if (isAllCaps) return w; // keep acronyms: HDFC, SBI, ICICI
        if (_bankAcronyms.contains(w.toLowerCase())) return w.toUpperCase();
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
}

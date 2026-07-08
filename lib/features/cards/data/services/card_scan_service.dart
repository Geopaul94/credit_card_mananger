import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Which face of the card is being scanned.
enum CardSide { front, back }

class CardScanResult {
  const CardScanResult({
    this.holderName,
    this.cardNumber,
    this.expiryDate,
    this.bankName,
    this.cardName,
  });

  final String? holderName;

  /// Full card number as read by OCR, formatted: "4532 1234 5678 9012"
  final String? cardNumber;

  /// MM/YY format
  final String? expiryDate;

  /// Issuing bank, matched from a keyword list.
  final String? bankName;

  /// Co-brand / product name (e.g. "Flipkart"), matched from a keyword list.
  final String? cardName;

  bool get hasAnyField =>
      holderName != null ||
      cardNumber != null ||
      expiryDate != null ||
      bankName != null ||
      cardName != null;

  /// Combines two scans (e.g. front + back), keeping this result's non-null
  /// fields and filling any gaps from [other].
  CardScanResult merge(CardScanResult other) => CardScanResult(
        holderName: holderName ?? other.holderName,
        cardNumber: cardNumber ?? other.cardNumber,
        expiryDate: expiryDate ?? other.expiryDate,
        bankName: bankName ?? other.bankName,
        cardName: cardName ?? other.cardName,
      );
}

class CardScanService {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Opens the camera for the given [side], runs on-device OCR, then deletes
  /// the captured image immediately. Returns null if the user cancelled.
  Future<CardScanResult?> scanSide(CardSide side) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (photo == null) return null;

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognized = await _recognizer.processImage(inputImage);
      return side == CardSide.front
          ? _parseFront(recognized.text)
          : _parseBack(recognized.text);
    } finally {
      final file = File(photo.path);
      if (await file.exists()) await file.delete();
    }
  }

  // ── Front: number, expiry, holder name, bank ───────────────────────────────

  CardScanResult _parseFront(String text) {
    final normalized = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    return CardScanResult(
      cardNumber: _parseNumber(normalized),
      expiryDate: _parseExpiry(normalized),
      holderName: _parseName(normalized),
      bankName: _detectBank(text),
      cardName: _detectCardName(text),
    );
  }

  // ── Back: bank / card-number fallback ──────────────────────────────────────

  CardScanResult _parseBack(String text) {
    final normalized = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    return CardScanResult(
      cardNumber: _parseNumber(normalized),
      bankName: _detectBank(text),
    );
  }

  // ── Field parsers ──────────────────────────────────────────────────────────

  String? _parseNumber(String normalized) {
    // PAN: four groups of digits separated by space or dash.
    final match = RegExp(
      r'\b(\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{1,4})\b',
    ).firstMatch(normalized);
    if (match == null) return null;
    final digits = match.group(1)!.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length < 12) return null;
    // Format as space-separated groups of 4.
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String? _parseExpiry(String normalized) {
    // MM/YY or MM-YY, tolerating spaces around the separator (OCR often adds
    // them, e.g. "VALID THRU 08 / 28"). The negative lookahead stops it from
    // grabbing the first two digits of a 4-digit year.
    final m = RegExp(r'(0[1-9]|1[0-2])\s*[\/\-]\s*(\d{2})(?!\d)')
        .firstMatch(normalized);
    return m == null ? null : '${m.group(1)}/${m.group(2)}';
  }

  String? _parseName(String normalized) {
    // 2+ consecutive ALL-CAPS words on a line with no digits.
    for (final line in normalized.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'\d').hasMatch(trimmed)) continue;
      if (!RegExp(r'^[A-Z][A-Z\s\-\.]+$').hasMatch(trimmed)) continue;
      final words =
          trimmed.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
      if (words.length >= 2) return words.join(' ');
    }
    return null;
  }

  String? _detectBank(String text) {
    final lower = text.toLowerCase();
    for (final entry in _bankKeywords.entries) {
      if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  // Ordered specific → generic so "state bank of india" wins over a bare
  // "sbi", "american express" over "amex", etc.
  static const _bankKeywords = <String, String>{
    'state bank of india': 'State Bank of India',
    'hdfc': 'HDFC Bank',
    'icici': 'ICICI Bank',
    'axis': 'Axis Bank',
    'kotak': 'Kotak Mahindra Bank',
    'indusind': 'IndusInd Bank',
    'idfc': 'IDFC First Bank',
    'yes bank': 'Yes Bank',
    'punjab national': 'Punjab National Bank',
    'bank of baroda': 'Bank of Baroda',
    'canara': 'Canara Bank',
    'union bank': 'Union Bank of India',
    'american express': 'American Express',
    'amex': 'American Express',
    'citibank': 'Citibank',
    'citi': 'Citibank',
    'hsbc': 'HSBC',
    'standard chartered': 'Standard Chartered',
    'chase': 'Chase',
    'bank of america': 'Bank of America',
    'wells fargo': 'Wells Fargo',
    'capital one': 'Capital One',
    'barclays': 'Barclays',
    'sbi': 'SBI',
  };

  String? _detectCardName(String text) {
    final lower = text.toLowerCase();
    for (final entry in _cardNameKeywords.entries) {
      if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  // Popular co-brand / product card names. Ordered specific → generic.
  static const _cardNameKeywords = <String, String>{
    'amazon pay': 'Amazon Pay',
    'amazon': 'Amazon Pay',
    'flipkart': 'Flipkart',
    'myntra': 'Myntra',
    'swiggy': 'Swiggy',
    'zomato': 'Zomato',
    'tata neu': 'Tata Neu',
    'simplyclick': 'SimplyCLICK',
    'simplysave': 'SimplySAVE',
    'smartbuy': 'SmartBuy',
    'millennia': 'Millennia',
    'moneyback': 'MoneyBack',
    'regalia': 'Regalia',
    'diners club': 'Diners Club',
    'diners': 'Diners Club',
    'magnus': 'Magnus',
    'infinia': 'Infinia',
    'coral': 'Coral',
    'rubyx': 'Rubyx',
    'indianoil': 'IndianOil',
    'vistara': 'Vistara',
    'irctc': 'IRCTC',
    'onecard': 'OneCard',
    'one card': 'OneCard',
    'cashback': 'Cashback',
    'platinum': 'Platinum',
    'signature': 'Signature',
    'elite': 'Elite',
    'select': 'Select',
  };

  void dispose() => _recognizer.close();
}

import 'package:equatable/equatable.dart';

class PaymentCard extends Equatable {
  const PaymentCard({
    required this.id,
    required this.holderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.typeLabel,
    this.cvv,
    this.bankName,
    this.cardName,
    this.dueDay,
    this.notes,
  });

  final String id;
  final String holderName;
  final String cardNumber; // digits only
  final String expiryDate; // MM/YY
  final String typeLabel;

  /// Security code, 3 digits (4 on Amex). Optional — null means the user
  /// chose not to store it, and every card saved before this feature existed
  /// loads with null. Never assume it is present.
  final String? cvv;
  final String? bankName;
  final String? cardName; // co-brand / product name, e.g. "Flipkart"
  final int? dueDay; // monthly due date — null means no reminder set
  final String? notes; // free-text notes (bank login, reminders, etc.)

  /// True when a security code is stored for this card.
  bool get hasCvv => cvv != null && cvv!.trim().isNotEmpty;

  // ── Expiry ─────────────────────────────────────────────────────────────────

  /// The moment this card stops being valid. A card expires at the *end* of
  /// its printed month, so an 08/28 card is good until 31 Aug 2028.
  /// Null when [expiryDate] isn't a well-formed MM/YY.
  DateTime? get expiresAt {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiryDate.trim());
    if (m == null) return null;
    final month = int.parse(m.group(1)!);
    if (month < 1 || month > 12) return null;
    final year = 2000 + int.parse(m.group(2)!);
    // Day 0 of the following month is the last day of this one.
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  /// True once the printed month has fully passed.
  bool get isExpired {
    final end = expiresAt;
    return end != null && DateTime.now().isAfter(end);
  }

  /// True while the card is still valid but runs out within [withinDays].
  /// Two months is early enough that a replacement usually arrives in time.
  bool isExpiringSoon({int withinDays = 60}) {
    final end = expiresAt;
    if (end == null) return false;
    final now = DateTime.now();
    if (now.isAfter(end)) return false; // already expired, not "soon"
    return end.difference(now).inDays <= withinDays;
  }

  /// Title shown in lists / app bar: "Bank - Card Name" when both exist,
  /// otherwise whichever is present (falling back to the card type).
  String get displayTitle {
    final bank = bankName?.trim();
    final name = cardName?.trim();
    final hasBank = bank != null && bank.isNotEmpty;
    final hasName = name != null && name.isNotEmpty;
    if (hasBank && hasName) return '$bank - $name';
    if (hasBank) return bank;
    if (hasName) return name;
    return typeLabel;
  }

  /// 4532 1234 5678 9012
  String get formattedNumber {
    final d = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  /// e.g. "5th", "15th", "21st"
  String get dueDayLabel {
    if (dueDay == null) return '';
    final d = dueDay!;
    final suffix = (d >= 11 && d <= 13)
        ? 'th'
        : switch (d % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$d$suffix';
  }

  /// The next upcoming due date (today or in the future), or null if no due
  /// day is set. Used as the billing-cycle key for paid tracking.
  DateTime? get nextDueDate {
    if (dueDay == null) return null;
    final now = DateTime.now();
    // Clamp to month length so day 31 lands on the month's last day
    // instead of overflowing into the next month.
    int clampDay(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return dueDay! > lastDay ? lastDay : dueDay!;
    }

    final today = DateTime(now.year, now.month, now.day);
    var due = DateTime(now.year, now.month, clampDay(now.year, now.month));
    if (due.isBefore(today)) {
      due = DateTime(now.year, now.month + 1, clampDay(now.year, now.month + 1));
    }
    return due;
  }

  /// Days until the next due date (0 = today, negative = overdue)
  int? get daysUntilDue {
    final due = nextDueDate;
    if (due == null) return null;
    final now = DateTime.now();
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// The due date relevant to reminders, plus how many days away it is.
  ///
  /// `delta` is positive when the bill is upcoming (days until due, 0 = today)
  /// and negative when overdue (days past due). A due date that passed up to one
  /// day ago is kept as the current cycle (delta -1) so we can still nudge
  /// "overdue by 1 day"; beyond that the cycle rolls to next month.
  ({DateTime date, int delta})? get reminderInfo {
    if (dueDay == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int clampDay(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return dueDay! > lastDay ? lastDay : dueDay!;
    }

    final thisMonthDue =
        DateTime(now.year, now.month, clampDay(now.year, now.month));
    if (!thisMonthDue.isBefore(today)) {
      return (date: thisMonthDue, delta: thisMonthDue.difference(today).inDays);
    }
    final overdue = today.difference(thisMonthDue).inDays;
    if (overdue <= 1) return (date: thisMonthDue, delta: -overdue);
    final nextDue =
        DateTime(now.year, now.month + 1, clampDay(now.year, now.month + 1));
    return (date: nextDue, delta: nextDue.difference(today).inDays);
  }

  PaymentCard copyWith({
    String? id,
    String? holderName,
    String? cardNumber,
    String? expiryDate,
    String? typeLabel,
    String? cvv,
    bool clearCvv = false,
    String? bankName,
    bool clearBankName = false,
    String? cardName,
    bool clearCardName = false,
    int? dueDay,
    bool clearDueDay = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      holderName: holderName ?? this.holderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      typeLabel: typeLabel ?? this.typeLabel,
      cvv: clearCvv ? null : (cvv ?? this.cvv),
      bankName: clearBankName ? null : (bankName ?? this.bankName),
      cardName: clearCardName ? null : (cardName ?? this.cardName),
      dueDay: clearDueDay ? null : (dueDay ?? this.dueDay),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  @override
  List<Object?> get props => [
        id,
        holderName,
        cardNumber,
        expiryDate,
        typeLabel,
        cvv,
        bankName,
        cardName,
        dueDay,
        notes,
      ];
}

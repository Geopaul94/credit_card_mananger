import 'package:equatable/equatable.dart';

class PaymentCard extends Equatable {
  const PaymentCard({
    required this.id,
    required this.holderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.typeLabel,
    required this.cvv,
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
  final String cvv;
  final String? bankName;
  final String? cardName; // co-brand / product name, e.g. "Flipkart"
  final int? dueDay; // monthly due date — null means no reminder set
  final String? notes; // free-text notes (bank login, reminders, etc.)

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
      cvv: cvv ?? this.cvv,
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

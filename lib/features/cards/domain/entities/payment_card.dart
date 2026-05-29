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
  final int? dueDay; // monthly due date — null means no reminder set
  final String? notes; // free-text notes (bank login, reminders, etc.)

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

  /// Days until the next due date (0 = today, negative = overdue)
  int? get daysUntilDue {
    if (dueDay == null) return null;
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, dueDay!);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, dueDay!);
    }
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
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
      dueDay: clearDueDay ? null : (dueDay ?? this.dueDay),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  @override
  List<Object?> get props =>
      [id, holderName, cardNumber, expiryDate, typeLabel, cvv, bankName, dueDay, notes];
}

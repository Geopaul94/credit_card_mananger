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
    this.cvv,
    this.bankName,
  });

  final String? holderName;

  /// Full card number as read by OCR, formatted: "4532 1234 5678 9012"
  final String? cardNumber;

  /// MM/YY format
  final String? expiryDate;

  /// 3–4 digit security code (read from the back of the card).
  final String? cvv;

  /// Issuing bank, matched from a keyword list.
  final String? bankName;

  bool get hasAnyField =>
      holderName != null ||
      cardNumber != null ||
      expiryDate != null ||
      cvv != null ||
      bankName != null;

  /// Combines two scans (e.g. front + back), keeping this result's non-null
  /// fields and filling any gaps from [other].
  CardScanResult merge(CardScanResult other) => CardScanResult(
        holderName: holderName ?? other.holderName,
        cardNumber: cardNumber ?? other.cardNumber,
        expiryDate: expiryDate ?? other.expiryDate,
        cvv: cvv ?? other.cvv,
        bankName: bankName ?? other.bankName,
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
    );
  }

  // ── Back: CVV (plus bank / card-number fallback) ───────────────────────────

  CardScanResult _parseBack(String text) {
    final normalized = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    return CardScanResult(
      cvv: _parseCvv(text),
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
    // MM/YY or MM-YY (not MM/YYYY, to avoid false positives).
    final m =
        RegExp(r'\b(0[1-9]|1[0-2])[\/\-](\d{2})\b').firstMatch(normalized);
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

  String? _parseCvv(String text) {
    // Prefer a value explicitly labelled CVV / CVC / CVV2 / CID.
    final labeled = RegExp(
      r'(?:cvv2?|cvc2?|cid)\D{0,6}(\d{3,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) return labeled.group(1);

    // Otherwise the first standalone 3-digit group on its own line.
    for (final line in text.split('\n')) {
      final m = RegExp(r'^\s*(\d{3})\s*$').firstMatch(line);
      if (m != null) return m.group(1);
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

  void dispose() => _recognizer.close();
}

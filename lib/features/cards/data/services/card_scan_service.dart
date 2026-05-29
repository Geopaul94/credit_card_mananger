import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class CardScanResult {
  const CardScanResult({
    this.holderName,
    this.cardNumber,
    this.expiryDate,
  });

  final String? holderName;

  /// Full card number as read by OCR, formatted: "4532 1234 5678 9012"
  final String? cardNumber;

  /// MM/YY format
  final String? expiryDate;

  bool get hasAnyField =>
      holderName != null || cardNumber != null || expiryDate != null;
}

class CardScanService {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Opens camera, runs on-device OCR, deletes the image immediately after.
  /// Returns null if the user cancelled.
  Future<CardScanResult?> scanFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (photo == null) return null;

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognized = await _recognizer.processImage(inputImage);
      return _parseCardText(recognized.text);
    } finally {
      final file = File(photo.path);
      if (await file.exists()) await file.delete();
    }
  }

  CardScanResult _parseCardText(String text) {
    final normalized = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // PAN: four groups of digits separated by space or dash
    String? cardNumber;
    final panMatch = RegExp(
      r'\b(\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{1,4})\b',
    ).firstMatch(normalized);
    if (panMatch != null) {
      final digits = panMatch.group(1)!.replaceAll(RegExp(r'[\s\-]'), '');
      if (digits.length >= 12) {
        // Format as space-separated groups of 4
        final buffer = StringBuffer();
        for (int i = 0; i < digits.length; i++) {
          if (i > 0 && i % 4 == 0) buffer.write(' ');
          buffer.write(digits[i]);
        }
        cardNumber = buffer.toString();
      }
    }

    // Expiry: MM/YY or MM-YY (not MM/YYYY to avoid false positives)
    String? expiryDate;
    final expiryMatch = RegExp(
      r'\b(0[1-9]|1[0-2])[\/\-](\d{2})\b',
    ).firstMatch(normalized);
    if (expiryMatch != null) {
      expiryDate = '${expiryMatch.group(1)}/${expiryMatch.group(2)}';
    }

    // Name: 2+ consecutive ALL-CAPS words, no digits in the line
    String? holderName;
    for (final line in normalized.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'\d').hasMatch(trimmed)) continue;
      if (!RegExp(r'^[A-Z][A-Z\s\-\.]+$').hasMatch(trimmed)) continue;
      final words =
          trimmed.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
      if (words.length >= 2) {
        holderName = words.join(' ');
        break;
      }
    }

    return CardScanResult(
      holderName: holderName,
      cardNumber: cardNumber,
      expiryDate: expiryDate,
    );
  }

  void dispose() => _recognizer.close();
}

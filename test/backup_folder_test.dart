import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:credit_cards/core/encryption/encryption_service.dart';
import 'package:credit_cards/core/storage/folder_storage.dart';
import 'package:credit_cards/features/cards/domain/entities/card_folder.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EncryptionService encryption;
  late FolderStorage folderStorage;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    encryption = EncryptionService(const FlutterSecureStorage());
    folderStorage = FolderStorage(encryption, prefs);
  });

  group('FolderStorage with AES encryption', () {
    test('saves and loads folders encrypted with AES-256', () async {
      final now = DateTime(2026, 9, 12);
      final folders = [
        CardFolder(
          id: 'f1',
          name: 'Shopping Cards',
          iconKey: 'shopping_bag',
          colorIndex: 2,
          cardIds: const ['card_1', 'card_2'],
          createdAt: now,
        ),
      ];

      await folderStorage.saveFolders(folders);

      // Verify that raw value in SharedPreferences is encrypted (contains ':' IV/Cipher separator)
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cv_card_folders_v1');
      expect(raw, isNotNull);
      expect(raw!.contains(':'), isTrue);
      expect(raw.contains('Shopping Cards'), isFalse); // ciphertext, not plain text

      // Load and verify decrypted values
      final loaded = await folderStorage.loadFolders();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'f1');
      expect(loaded.first.name, 'Shopping Cards');
      expect(loaded.first.iconKey, 'shopping_bag');
      expect(loaded.first.colorIndex, 2);
      expect(loaded.first.cardIds, ['card_1', 'card_2']);
    });

    test('backward compatibility: loads unencrypted legacy JSON', () async {
      final legacyJson = jsonEncode([
        {
          'id': 'legacy_1',
          'name': 'Travel',
          'iconKey': 'flight',
          'colorIndex': 1,
          'cardIds': ['card_99'],
          'createdAt': '2026-01-01T00:00:00.000',
        }
      ]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cv_card_folders_v1', legacyJson);

      final loaded = await folderStorage.loadFolders();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'legacy_1');
      expect(loaded.first.name, 'Travel');
      expect(loaded.first.cardIds, ['card_99']);
    });
  });

  group('Drive Backup payload with Folders and AES', () {
    test('AES encrypts both cards and folders in Drive backup payload', () {
      const googleId = 'user_123456789';
      final cards = [
        const PaymentCard(
          id: 'c1',
          holderName: 'Geo Paulson',
          cardNumber: '4532123456789012',
          expiryDate: '12/28',
          typeLabel: 'Credit',
          cvv: '123',
          bankName: 'HDFC',
          cardName: 'Regalia',
        ),
      ];
      final folders = [
        CardFolder(
          id: 'f1',
          name: 'Premium',
          iconKey: 'star',
          colorIndex: 0,
          cardIds: const ['c1'],
          createdAt: DateTime(2026, 9, 12),
        ),
      ];

      // Build payload JSON
      final json = jsonEncode({
        'version': 2,
        'created': DateTime.now().toIso8601String(),
        'cards': cards
            .map((c) => {
                  'id': c.id,
                  'holderName': c.holderName,
                  'cardNumber': c.cardNumber,
                  'expiryDate': c.expiryDate,
                  'typeLabel': c.typeLabel,
                  if (c.cvv != null) 'cvv': c.cvv,
                  if (c.bankName != null) 'bankName': c.bankName,
                  if (c.cardName != null) 'cardName': c.cardName,
                  if (c.dueDay != null) 'dueDay': c.dueDay,
                  if (c.notes != null) 'notes': c.notes,
                })
            .toList(),
        'folders': folders.map((f) => f.toMap()).toList(),
      });

      // Encrypt with Google ID
      final encryptedPayload = encryption.encryptForBackup(json, googleId);
      expect(encryptedPayload.contains('Regalia'), isFalse);
      expect(encryptedPayload.contains('Premium'), isFalse);

      // Decrypt and verify
      final decryptedJson = encryption.decryptFromBackup(encryptedPayload, googleId);
      final map = jsonDecode(decryptedJson) as Map<String, dynamic>;
      expect(map['version'], 2);

      final decodedCards = (map['cards'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      expect(decodedCards.length, 1);
      expect(decodedCards.first['cardNumber'], '4532123456789012');
      expect(decodedCards.first['cvv'], '123');

      final decodedFolders = (map['folders'] as List<dynamic>)
          .map((e) => CardFolder.fromMap(e as Map<String, dynamic>))
          .toList();
      expect(decodedFolders.length, 1);
      expect(decodedFolders.first.name, 'Premium');
      expect(decodedFolders.first.cardIds, ['c1']);
    });
  });
}

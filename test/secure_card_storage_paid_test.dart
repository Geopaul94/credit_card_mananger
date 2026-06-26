import 'package:credit_cards/core/encryption/encryption_service.dart';
import 'package:credit_cards/core/storage/secure_card_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureCardStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // The paid map / backup metadata / auto-backup toggle don't touch
    // encryption, so a dummy EncryptionService is fine for those tests.
    storage = SecureCardStorage(
      EncryptionService(const FlutterSecureStorage()),
      prefs,
    );
  });

  group('SecureCardStorage paid map', () {
    test('loadPaidMap empty when nothing saved', () {
      expect(storage.loadPaidMap(), isEmpty);
    });

    test('round-trips multiple entries', () async {
      final input = {
        'card-1': DateTime(2026, 7, 15),
        'card-2': DateTime(2026, 8, 1),
      };
      await storage.savePaidMap(input);
      final out = storage.loadPaidMap();
      expect(out.length, 2);
      expect(out['card-1'], DateTime(2026, 7, 15));
      expect(out['card-2'], DateTime(2026, 8, 1));
    });

    test('saving empty map clears the stored value', () async {
      await storage.savePaidMap({'a': DateTime(2026, 7, 15)});
      expect(storage.loadPaidMap(), isNotEmpty);
      await storage.savePaidMap({});
      expect(storage.loadPaidMap(), isEmpty);
    });
  });

  group('SecureCardStorage backup metadata', () {
    test('lastBackupTime starts null', () {
      expect(storage.lastBackupTime, null);
    });
    test('markBackedUp sets a recent time', () async {
      final before = DateTime.now();
      await storage.markBackedUp();
      final t = storage.lastBackupTime!;
      expect(t.isAfter(before.subtract(const Duration(seconds: 5))), true);
      expect(t.isBefore(DateTime.now().add(const Duration(seconds: 5))), true);
    });
    test('needsAutoBackup true when never backed up', () {
      expect(storage.needsAutoBackup, true);
    });
    test('needsAutoBackup false within 24h of last backup', () async {
      await storage.markBackedUp();
      expect(storage.needsAutoBackup, false);
    });
  });

  group('SecureCardStorage auto-backup toggle', () {
    test('defaults to enabled', () {
      expect(storage.isAutoBackupEnabled, true);
    });
    test('persists user choice', () async {
      await storage.setAutoBackupEnabled(false);
      expect(storage.isAutoBackupEnabled, false);
      await storage.setAutoBackupEnabled(true);
      expect(storage.isAutoBackupEnabled, true);
    });
  });
}

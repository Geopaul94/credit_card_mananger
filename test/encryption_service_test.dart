import 'package:credit_cards/core/encryption/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // EncryptionService takes FlutterSecureStorage but the backup path doesn't
  // touch it — the key is derived from googleUserId. We can construct the
  // service with a dummy instance and only exercise the backup methods.
  final svc = EncryptionService(const FlutterSecureStorage());

  group('EncryptionService backup round-trip', () {
    test('encrypt then decrypt with same googleId returns original', () {
      const plain = '{"cards":[{"id":"x","holderName":"JOHN DOE"}]}';
      final cipher = svc.encryptForBackup(plain, 'google-id-123');
      expect(cipher, isNot(equals(plain)));
      final back = svc.decryptFromBackup(cipher, 'google-id-123');
      expect(back, plain);
    });

    test('two encryptions of same plaintext produce different ciphers (IV)', () {
      const plain = 'hello';
      final a = svc.encryptForBackup(plain, 'g-1');
      final b = svc.encryptForBackup(plain, 'g-1');
      expect(a, isNot(equals(b)));
      // Both still decrypt back to the same plaintext.
      expect(svc.decryptFromBackup(a, 'g-1'), plain);
      expect(svc.decryptFromBackup(b, 'g-1'), plain);
    });

    test('decrypting with a different googleId throws', () {
      final cipher = svc.encryptForBackup('secret', 'user-a');
      expect(() => svc.decryptFromBackup(cipher, 'user-b'), throwsA(anything));
    });

    test('malformed payload (no IV separator) throws FormatException', () {
      expect(
        () => svc.decryptFromBackup('not-a-real-payload', 'any'),
        throwsA(isA<FormatException>()),
      );
    });

    test('round-trip preserves unicode content', () {
      const plain = 'राम कुमार · 4532 €100';
      final cipher = svc.encryptForBackup(plain, 'g-id');
      expect(svc.decryptFromBackup(cipher, 'g-id'), plain);
    });
  });
}

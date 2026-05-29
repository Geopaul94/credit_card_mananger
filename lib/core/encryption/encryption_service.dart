import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-CBC encryption.
///
/// Two contexts:
///  • Local — random key stored in [FlutterSecureStorage] (device-specific).
///  • Backup — key derived from the user's Google ID so the same key is
///    reproduced on any device after sign-in, enabling cross-device restore.
class EncryptionService {
  EncryptionService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _localKeyName = 'cv_local_aes_key_v1';

  // ── Local encryption (device key) ─────────────────────────────────────────

  Future<String> encryptLocal(String plaintext) async {
    final key = await _localKey();
    return _encrypt(plaintext, key);
  }

  Future<String> decryptLocal(String payload) async {
    final key = await _localKey();
    return _decrypt(payload, key);
  }

  Future<Key> _localKey() async {
    var b64 = await _secureStorage.read(key: _localKeyName);
    if (b64 == null) {
      final k = Key.fromSecureRandom(32);
      b64 = k.base64;
      await _secureStorage.write(key: _localKeyName, value: b64);
    }
    return Key.fromBase64(b64);
  }

  // ── Backup encryption (Google-ID derived key) ──────────────────────────────

  /// Encrypts for Drive backup. The key is derived from [googleUserId] so it
  /// can be reproduced on any device the user signs into with the same account.
  String encryptForBackup(String plaintext, String googleUserId) =>
      _encrypt(plaintext, _backupKey(googleUserId));

  String decryptFromBackup(String payload, String googleUserId) =>
      _decrypt(payload, _backupKey(googleUserId));

  Key _backupKey(String googleUserId) {
    final bytes = sha256
        .convert(utf8.encode('CardVaultBackup_v1_$googleUserId'))
        .bytes;
    return Key(Uint8List.fromList(bytes));
  }

  // ── AES-256-CBC core ───────────────────────────────────────────────────────

  /// Returns "ivBase64:cipherBase64".
  String _encrypt(String plaintext, Key key) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decrypt(String payload, Key key) {
    final sep = payload.indexOf(':');
    if (sep < 0) throw const FormatException('Invalid encrypted payload');
    final iv = IV.fromBase64(payload.substring(0, sep));
    final cipher = Encrypted.fromBase64(payload.substring(sep + 1));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(cipher, iv: iv);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cards/domain/entities/card_folder.dart';
import '../encryption/encryption_service.dart';

/// Storage helper to persist and retrieve card folders securely with AES encryption.
class FolderStorage {
  const FolderStorage(this._encryption, this._prefs);

  final EncryptionService _encryption;
  final SharedPreferences _prefs;

  static const _foldersKey = 'cv_card_folders_v1';

  /// Loads all folders saved in preferences, decrypting if encrypted.
  Future<List<CardFolder>> loadFolders() async {
    final raw = _prefs.getString(_foldersKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final trimmed = raw.trim();
      final String jsonStr;
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        // Plain JSON migration fallback
        jsonStr = trimmed;
      } else {
        jsonStr = await _encryption.decryptLocal(trimmed);
      }
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => CardFolder.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the list of folders with local AES encryption.
  Future<void> saveFolders(List<CardFolder> folders) async {
    final raw = jsonEncode(folders.map((f) => f.toMap()).toList());
    final encrypted = await _encryption.encryptLocal(raw);
    await _prefs.setString(_foldersKey, encrypted);
  }
}


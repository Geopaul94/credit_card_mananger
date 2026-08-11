import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Thin HTTP client that injects a Google OAuth bearer token into every request.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request..headers.addAll(_headers));

  @override
  void close() => _inner.close();
}

/// Handles Google Sign-In and Drive AppData operations.
///
/// Backup files are stored in the Drive **AppData** space — hidden from the
/// user's regular Drive view and removed automatically if the app is
/// uninstalled. Each backup replaces the previous one (single file).
class GoogleDriveService {
  static const _backupFileName = 'cardvault_backup_v1.enc';
  static const _appDataFolder = 'appDataFolder';

  late final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;

  GoogleDriveService() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        drive.DriveApi.driveAppdataScope,
      ],
    );
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
    });
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Interactive sign-in. Disconnects any existing session first so a stale
  /// token can't silently fail later — same as the debt-tracker pattern.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _googleSignIn.disconnect().catchError((_) => null);
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      // Verify we can obtain auth headers — if this fails, the sign-in is bad.
      final headers = await account.authHeaders;
      if (headers.isEmpty) return null;
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('GoogleDriveService.signIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('GoogleDriveService.signOut error: $e');
    } finally {
      _currentUser = null;
    }
  }

  /// Restores a previous session silently (no UI shown).
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('GoogleDriveService.signInSilently error: $e');
      return null;
    }
  }

  /// Ensures we have a Drive session without showing UI. Returns true if OK.
  Future<bool> ensureSignedIn() async {
    if (_currentUser != null) return true;
    final account = await signInSilently();
    return account != null;
  }

  // ── Drive API client ───────────────────────────────────────────────────────

  Future<drive.DriveApi> _api() async {
    final user = _currentUser;
    if (user == null) throw Exception('Not signed in to Google');
    final headers = await user.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  Future<String?> _existingFileId(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: _appDataFolder,
      q: "name = '$_backupFileName'",
      $fields: 'files(id)',
    );
    return result.files?.firstOrNull?.id;
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> uploadBackup(String encryptedContent) async {
    final api = await _api();
    final bytes = utf8.encode(encryptedContent);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/octet-stream',
    );

    final existingId = await _existingFileId(api);
    if (existingId != null) {
      await api.files.update(
        drive.File()..name = _backupFileName,
        existingId,
        uploadMedia: media,
      );
    } else {
      final meta = drive.File()
        ..name = _backupFileName
        ..parents = [_appDataFolder];
      await api.files.create(meta, uploadMedia: media);
    }
  }

  // ── Download ───────────────────────────────────────────────────────────────

  Future<String?> downloadBackup() async {
    final api = await _api();
    final fileId = await _existingFileId(api);
    if (fileId == null) return null;

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await media.stream.expand((b) => b).toList();
    return utf8.decode(bytes);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Removes the backup file from Drive. The device's own cards are untouched
  /// — this only affects what a future restore would pull down. A no-op if
  /// there is no backup to delete.
  Future<void> deleteBackup() async {
    final api = await _api();
    final fileId = await _existingFileId(api);
    if (fileId == null) return;
    await api.files.delete(fileId);
  }

  // ── Metadata ───────────────────────────────────────────────────────────────

  Future<DateTime?> lastBackupTime() async {
    try {
      final api = await _api();
      final fileId = await _existingFileId(api);
      if (fileId == null) return null;
      final file = await api.files.get(
        fileId,
        $fields: 'modifiedTime',
      ) as drive.File;
      return file.modifiedTime;
    } catch (_) {
      return null;
    }
  }

  Future<bool> backupExists() async {
    try {
      final api = await _api();
      return await _existingFileId(api) != null;
    } catch (_) {
      return false;
    }
  }
}

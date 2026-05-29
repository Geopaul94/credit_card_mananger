import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Handles Google Sign-In and Drive AppData operations.
///
/// The backup file is stored in the Drive **AppData** folder — it is
/// invisible to the user in their regular Drive view and is automatically
/// removed if the app is uninstalled.
class GoogleDriveService {
  static const _backupFileName = 'cardvault_backup_v1.enc';
  static const _appDataFolder = 'appDataFolder';

  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() => _googleSignIn.disconnect();

  Future<bool> get isSignedIn => _googleSignIn.isSignedIn();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Silently restores a previous sign-in session (no UI shown).
  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  // ── Drive helpers ──────────────────────────────────────────────────────────

  Future<drive.DriveApi> _api() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('Not authenticated with Google');
    return drive.DriveApi(client);
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
    final media = drive.Media(Stream.value(bytes), bytes.length,
        contentType: 'application/octet-stream');

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

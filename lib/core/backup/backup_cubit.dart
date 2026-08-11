import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/cards/domain/entities/payment_card.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../encryption/encryption_service.dart';
import '../storage/secure_card_storage.dart';
import 'google_drive_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum BackupPhase {
  idle,
  signingIn,
  backingUp,
  restoring,
  deletingCloud,
  success,
  error,
}

class BackupState extends Equatable {
  const BackupState({
    this.phase = BackupPhase.idle,
    this.account,
    this.lastDriveBackup,
    this.restoredCount,
    this.errorMessage,
    this.autoEnabled = true,
  });

  final BackupPhase phase;
  final GoogleSignInAccount? account;
  final DateTime? lastDriveBackup;
  final int? restoredCount; // non-null after a successful restore
  final String? errorMessage;
  final bool autoEnabled;

  bool get isLoading =>
      phase == BackupPhase.signingIn ||
      phase == BackupPhase.backingUp ||
      phase == BackupPhase.restoring ||
      phase == BackupPhase.deletingCloud;

  BackupState copyWith({
    BackupPhase? phase,
    GoogleSignInAccount? account,
    bool clearAccount = false,
    DateTime? lastDriveBackup,
    bool clearDriveTime = false,
    int? restoredCount,
    bool clearRestoredCount = false,
    String? errorMessage,
    bool clearError = false,
    bool? autoEnabled,
  }) {
    return BackupState(
      phase: phase ?? this.phase,
      account: clearAccount ? null : (account ?? this.account),
      lastDriveBackup:
          clearDriveTime ? null : (lastDriveBackup ?? this.lastDriveBackup),
      restoredCount:
          clearRestoredCount ? null : (restoredCount ?? this.restoredCount),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      autoEnabled: autoEnabled ?? this.autoEnabled,
    );
  }

  @override
  List<Object?> get props =>
      [phase, account, lastDriveBackup, restoredCount, errorMessage, autoEnabled];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class BackupCubit extends Cubit<BackupState> {
  BackupCubit(
    this._drive,
    this._encryption,
    this._storage,
    this._repository,
  ) : super(const BackupState());

  final GoogleDriveService _drive;
  final EncryptionService _encryption;
  final SecureCardStorage _storage;
  final CardRepository _repository;

  // ── Initialise (call on app start / profile open) ─────────────────────────

  Future<void> initialize() async {
    final autoEnabled = _storage.isAutoBackupEnabled;
    final account = await _drive.signInSilently();
    final driveTime = account != null ? await _drive.lastBackupTime() : null;
    emit(state.copyWith(
      account: account,
      lastDriveBackup: driveTime,
      autoEnabled: autoEnabled,
    ));
  }

  // ── Sign in / out ─────────────────────────────────────────────────────────

  /// Connects a Google account and, when it is safe to do so, immediately
  /// protects what is already on the device by backing it up.
  ///
  /// [cards] is the current vault. The automatic backup runs only when there
  /// are cards to save *and* Drive holds no backup yet — the point is to get a
  /// first-time user protected the moment they connect, without ever writing
  /// over a backup they might be about to restore. Someone who reinstalls,
  /// adds one card, then signs in would otherwise replace a ten-card backup
  /// with a one-card one. When a backup already exists the user chooses
  /// explicitly, on the backup screen.
  Future<void> signIn({List<PaymentCard> cards = const []}) async {
    emit(state.copyWith(phase: BackupPhase.signingIn, clearError: true));
    final account = await _drive.signIn();
    if (account == null) {
      emit(state.copyWith(
        phase: BackupPhase.error,
        errorMessage: 'Sign-in cancelled or failed. Try again.',
      ));
      return;
    }
    final driveTime = await _drive.lastBackupTime();
    emit(state.copyWith(
      phase: BackupPhase.idle,
      account: account,
      lastDriveBackup: driveTime,
    ));

    if (cards.isNotEmpty && driveTime == null) {
      await backupNow(cards);
    }
  }

  Future<void> signOut() async {
    await _drive.signOut();
    await _storage.setAutoBackupEnabled(false);
    emit(state.copyWith(
      phase: BackupPhase.idle,
      clearAccount: true,
      clearDriveTime: true,
      autoEnabled: false,
    ));
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  Future<void> backupNow(List<PaymentCard> cards) async {
    final account = state.account;
    if (account == null) {
      emit(state.copyWith(
          phase: BackupPhase.error,
          errorMessage: 'Sign in with Google first.'));
      return;
    }
    if (cards.isEmpty) {
      emit(state.copyWith(
          phase: BackupPhase.error,
          errorMessage: 'Nothing to back up — add a card first.'));
      return;
    }
    emit(state.copyWith(phase: BackupPhase.backingUp, clearError: true));
    try {
      final payload = _buildPayload(cards, account.id);
      await _drive.uploadBackup(payload);
      await _storage.markBackedUp();

      final driveTime = await _drive.lastBackupTime();
      emit(state.copyWith(
        phase: BackupPhase.success,
        lastDriveBackup: driveTime ?? DateTime.now(),
        clearRestoredCount: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: BackupPhase.error,
        errorMessage: 'Backup failed: ${e.toString()}',
      ));
    }
  }

  // ── Auto-backup toggle ─────────────────────────────────────────────────────

  Future<void> setAutoBackup(bool enabled) async {
    await _storage.setAutoBackupEnabled(enabled);
    emit(state.copyWith(autoEnabled: enabled));
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<void> restore() async {
    final account = state.account;
    if (account == null) {
      emit(state.copyWith(
          phase: BackupPhase.error,
          errorMessage: 'Sign in with Google first.'));
      return;
    }
    emit(state.copyWith(phase: BackupPhase.restoring, clearError: true));
    try {
      final payload = await _drive.downloadBackup();
      if (payload == null) {
        emit(state.copyWith(
          phase: BackupPhase.error,
          errorMessage: 'No backup found in Google Drive for this account.',
        ));
        return;
      }
      final cards = _parsePayload(payload, account.id);
      await _repository.replaceAll(cards);
      // Reset the auto-backup window so a fresh-device restore doesn't
      // immediately trigger an auto-backup on the next card load.
      await _storage.markBackedUp();
      emit(state.copyWith(
        phase: BackupPhase.success,
        restoredCount: cards.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: BackupPhase.error,
        errorMessage: 'Restore failed: ${e.toString()}',
      ));
    }
  }

  // ── Delete cloud backup ───────────────────────────────────────────────────

  /// Removes the Drive backup only — the device's own cards are never
  /// touched by this. The confirmation that this is what the user wants
  /// happens in the UI before this is called; this method just does it.
  Future<void> deleteCloudBackup() async {
    if (state.account == null) return;
    emit(state.copyWith(phase: BackupPhase.deletingCloud, clearError: true));
    try {
      await _drive.deleteBackup();
      emit(state.copyWith(
        phase: BackupPhase.idle,
        clearDriveTime: true,
        clearRestoredCount: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: BackupPhase.error,
        errorMessage: 'Could not delete the cloud backup: ${e.toString()}',
      ));
    }
  }

  // ── Auto-backup trigger ───────────────────────────────────────────────────

  /// Called when the app unlocks. Silently backs up once per day if enabled.
  Future<void> autoBackupIfNeeded(List<PaymentCard> cards) async {
    if (!_storage.isAutoBackupEnabled) return;
    if (!_storage.needsAutoBackup) return;
    if (cards.isEmpty) return;
    if (state.account == null) {
      final account = await _drive.signInSilently();
      if (account == null) return;
      emit(state.copyWith(account: account));
    }
    await backupNow(cards);
  }

  // ── Reset to idle (dismiss error/success) ─────────────────────────────────

  void dismiss() => emit(state.copyWith(phase: BackupPhase.idle, clearError: true));

  // ── Serialisation ─────────────────────────────────────────────────────────

  String _buildPayload(List<PaymentCard> cards, String googleId) {
    final json = jsonEncode({
      'version': 1,
      'created': DateTime.now().toIso8601String(),
      'cards': cards
          .map((c) => {
                'id': c.id,
                'holderName': c.holderName,
                'cardNumber': c.cardNumber,
                'expiryDate': c.expiryDate,
                'typeLabel': c.typeLabel,
                // Included so a restore on a new phone is lossless. The whole
                // payload is encrypted before it ever reaches Drive.
                if (c.cvv != null) 'cvv': c.cvv,
                if (c.bankName != null) 'bankName': c.bankName,
                if (c.cardName != null) 'cardName': c.cardName,
                if (c.dueDay != null) 'dueDay': c.dueDay,
                if (c.notes != null) 'notes': c.notes,
              })
          .toList(),
    });
    return _encryption.encryptForBackup(json, googleId);
  }

  List<PaymentCard> _parsePayload(String payload, String googleId) {
    final json = _encryption.decryptFromBackup(payload, googleId);
    final map = jsonDecode(json) as Map<String, dynamic>;
    final list = map['cards'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return PaymentCard(
        id: m['id'] as String,
        holderName: m['holderName'] as String,
        cardNumber: m['cardNumber'] as String,
        expiryDate: m['expiryDate'] as String,
        typeLabel: m['typeLabel'] as String,
        // Backups taken before CVV support simply have no 'cvv' key.
        cvv: m['cvv'] as String?,
        bankName: m['bankName'] as String?,
        cardName: m['cardName'] as String?,
        dueDay: m['dueDay'] as int?,
        notes: m['notes'] as String?,
      );
    }).toList();
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cards/data/models/payment_card_model.dart';
import '../../features/cards/domain/entities/payment_card.dart';
import '../encryption/encryption_service.dart';

/// Persists cards as an AES-encrypted JSON blob in SharedPreferences.
class SecureCardStorage {
  SecureCardStorage(this._encryption, this._prefs);

  final EncryptionService _encryption;
  final SharedPreferences _prefs;

  static const _cardsKey = 'cv_cards_enc_v1';
  static const _lastBackupKey = 'cv_last_backup_epoch';
  static const _paidKey = 'cv_paid_v1';
  static const _autoBackupEnabledKey = 'cv_auto_backup_enabled';

  // ── Card persistence ───────────────────────────────────────────────────────

  Future<void> saveCards(List<PaymentCard> cards) async {
    final json = jsonEncode(cards.map(_toMap).toList());
    final encrypted = await _encryption.encryptLocal(json);
    await _prefs.setString(_cardsKey, encrypted);
  }

  Future<List<PaymentCard>> loadCards() async {
    final encrypted = _prefs.getString(_cardsKey);
    if (encrypted == null || encrypted.isEmpty) return [];
    try {
      final json = await _encryption.decryptLocal(encrypted);
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => _fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Corrupt / unreadable data — return empty rather than crash.
      return [];
    }
  }

  // ── Replace all (used by restore) ──────────────────────────────────────────

  Future<void> replaceAll(List<PaymentCard> cards) => saveCards(cards);

  // ── Paid-status persistence ─────────────────────────────────────────────────
  // Maps cardId → the due date that payment covers. A card counts as "paid"
  // while that date is today-or-later; once it passes, the next cycle starts
  // unpaid. Not encrypted — only card IDs (timestamps) and dates.

  Future<void> savePaidMap(Map<String, DateTime> map) async {
    if (map.isEmpty) {
      await _prefs.remove(_paidKey);
      return;
    }
    final encoded =
        jsonEncode(map.map((k, v) => MapEntry(k, v.toIso8601String())));
    await _prefs.setString(_paidKey, encoded);
  }

  Map<String, DateTime> loadPaidMap() {
    final raw = _prefs.getString(_paidKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
    } catch (_) {
      return {};
    }
  }

  // ── Last backup metadata ───────────────────────────────────────────────────

  DateTime? get lastBackupTime {
    final epoch = _prefs.getInt(_lastBackupKey);
    return epoch == null ? null : DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  Future<void> markBackedUp() =>
      _prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);

  /// True when no backup has ever run or the last one was ≥ 1 day ago.
  bool get needsAutoBackup {
    final last = lastBackupTime;
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 24;
  }

  // ── Auto-backup toggle ─────────────────────────────────────────────────────

  /// Whether daily auto-backup is enabled. Defaults to true.
  bool get isAutoBackupEnabled =>
      _prefs.getBool(_autoBackupEnabledKey) ?? true;

  Future<void> setAutoBackupEnabled(bool value) =>
      _prefs.setBool(_autoBackupEnabledKey, value);

  // ── JSON helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(PaymentCard c) => {
        'id': c.id,
        'holderName': c.holderName,
        'cardNumber': c.cardNumber,
        'expiryDate': c.expiryDate,
        'typeLabel': c.typeLabel,
        if (c.bankName != null) 'bankName': c.bankName,
        if (c.cardName != null) 'cardName': c.cardName,
        if (c.dueDay != null) 'dueDay': c.dueDay,
        if (c.notes != null) 'notes': c.notes,
      };

  static PaymentCard _fromMap(Map<String, dynamic> m) => PaymentCardModel(
        id: m['id'] as String,
        holderName: m['holderName'] as String,
        cardNumber: m['cardNumber'] as String,
        expiryDate: m['expiryDate'] as String,
        typeLabel: m['typeLabel'] as String,
        bankName: m['bankName'] as String?,
        cardName: m['cardName'] as String?,
        dueDay: m['dueDay'] as int?,
        notes: m['notes'] as String?,
      );
}

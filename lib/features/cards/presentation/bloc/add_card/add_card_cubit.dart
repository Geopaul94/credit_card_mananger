import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/card_scan_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AddCardState extends Equatable {
  const AddCardState({
    this.cardType = 'Credit',
    this.selectedDueDay,
    this.isScanning = false,
    this.wasScanned = false,
    this.showCvv = false,
    this.scanResult,
  });

  final String cardType;

  /// Selected due day-of-month (1–31). null ⇒ no reminder.
  final int? selectedDueDay;
  final bool isScanning;
  final bool wasScanned;

  /// Whether the CVV field shows its digits. Only ever true while the user is
  /// still typing the card in — it resets every time the screen is opened.
  final bool showCvv;
  final CardScanResult? scanResult; // accumulates across front/back scans

  int? get effectiveDueDay => selectedDueDay;

  AddCardState copyWith({
    String? cardType,
    int? selectedDueDay,
    bool clearDueDay = false,
    bool? isScanning,
    bool? wasScanned,
    bool? showCvv,
    CardScanResult? scanResult,
    bool clearScan = false,
  }) {
    return AddCardState(
      cardType: cardType ?? this.cardType,
      selectedDueDay:
          clearDueDay ? null : (selectedDueDay ?? this.selectedDueDay),
      isScanning: isScanning ?? this.isScanning,
      wasScanned: wasScanned ?? this.wasScanned,
      showCvv: showCvv ?? this.showCvv,
      scanResult: clearScan ? null : (scanResult ?? this.scanResult),
    );
  }

  @override
  List<Object?> get props =>
      [cardType, selectedDueDay, isScanning, wasScanned, showCvv, scanResult];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AddCardCubit extends Cubit<AddCardState> {
  AddCardCubit(this._scanService) : super(const AddCardState());

  final CardScanService _scanService;

  // ── Card type ───────────────────────────────────────────────────────────────

  void selectType(String type) => emit(state.copyWith(cardType: type));

  // ── Due day (null ⇒ no reminder) ──────────────────────────────────────────

  void selectDueDay(int day) => emit(state.copyWith(selectedDueDay: day));

  void clearDueDay() => emit(state.copyWith(clearDueDay: true));

  // ── CVV visibility ────────────────────────────────────────────────────────

  void toggleCvv() => emit(state.copyWith(showCvv: !state.showCvv));

  // ── Scan front / back ─────────────────────────────────────────────────────
  // Each captures one side, OCRs it, and merges the result into [scanResult]
  // (existing values win; gaps are filled). Returns true if a photo was taken,
  // false if the user cancelled the camera.

  Future<bool> scanFront() => _scan(CardSide.front);

  Future<bool> scanBack() => _scan(CardSide.back);

  Future<bool> _scan(CardSide side) async {
    if (state.isScanning) return false;
    emit(state.copyWith(isScanning: true));
    try {
      final result = await _scanService.scanSide(side);
      if (isClosed) return false;
      if (result == null) {
        emit(state.copyWith(isScanning: false));
        return false; // cancelled
      }
      final merged = state.scanResult?.merge(result) ?? result;
      emit(state.copyWith(
        isScanning: false,
        wasScanned: merged.hasAnyField,
        scanResult: merged,
      ));
      return true;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isScanning: false));
      return false;
    }
  }

  void dismissScannedBanner() =>
      emit(state.copyWith(wasScanned: false, clearScan: true));
}

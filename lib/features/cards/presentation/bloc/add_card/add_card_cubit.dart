import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/card_scan_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AddCardState extends Equatable {
  const AddCardState({
    this.cardType = 'Credit',
    this.selectedDueDay,
    this.useCustomDay = false,
    this.isScanning = false,
    this.wasScanned = false,
    this.showCvv = false,
    this.scanResult,
  });

  final String cardType;
  final int? selectedDueDay;
  final bool useCustomDay;
  final bool isScanning;
  final bool wasScanned;
  final bool showCvv;
  final CardScanResult? scanResult; // non-null after a successful scan

  /// The effective due day — custom text-field value handled by the widget.
  int? get effectiveDueDay => useCustomDay ? null : selectedDueDay;

  AddCardState copyWith({
    String? cardType,
    int? selectedDueDay,
    bool clearDueDay = false,
    bool? useCustomDay,
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
      useCustomDay: useCustomDay ?? this.useCustomDay,
      isScanning: isScanning ?? this.isScanning,
      wasScanned: wasScanned ?? this.wasScanned,
      showCvv: showCvv ?? this.showCvv,
      scanResult: clearScan ? null : (scanResult ?? this.scanResult),
    );
  }

  @override
  List<Object?> get props => [
        cardType,
        selectedDueDay,
        useCustomDay,
        isScanning,
        wasScanned,
        showCvv,
        scanResult,
      ];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AddCardCubit extends Cubit<AddCardState> {
  AddCardCubit(this._scanService) : super(const AddCardState());

  final CardScanService _scanService;

  // ── Card type ─────────────────────────────────────────────────────────────

  void selectType(String type) => emit(state.copyWith(cardType: type));

  // ── Due day ───────────────────────────────────────────────────────────────

  void selectDueDay(int day) =>
      emit(state.copyWith(selectedDueDay: day, useCustomDay: false));

  void enableCustomDay() =>
      emit(state.copyWith(useCustomDay: true, clearDueDay: true));

  void clearDueDay() =>
      emit(state.copyWith(clearDueDay: true, useCustomDay: false));

  // ── CVV visibility ────────────────────────────────────────────────────────

  void toggleCvv() => emit(state.copyWith(showCvv: !state.showCvv));

  // ── Scan card ─────────────────────────────────────────────────────────────

  Future<void> scanCard() async {
    if (state.isScanning) return;
    emit(state.copyWith(isScanning: true, clearScan: true));
    try {
      final result = await _scanService.scanFromCamera();
      if (isClosed) return;
      if (result != null && result.hasAnyField) {
        emit(state.copyWith(isScanning: false, wasScanned: true, scanResult: result));
      } else {
        emit(state.copyWith(isScanning: false));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isScanning: false));
    }
  }

  void dismissScannedBanner() => emit(state.copyWith(wasScanned: false, clearScan: true));
}

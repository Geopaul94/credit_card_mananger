import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manual text-size override. [system] means "don't override" — main.dart's
/// existing clamp on the platform's own textScaler still applies. Any other
/// value replaces the platform value outright.
enum TextSizeOption {
  system(null),
  small(0.9),
  standard(1.0),
  large(1.15);

  const TextSizeOption(this.scaleFactor);

  /// Null for [system]; otherwise the fixed scale to apply.
  final double? scaleFactor;
}

/// How long the app waits after backgrounding before it re-locks. Separate
/// from AuthCubit's trusted-interruption grace window (which forgives only
/// the camera's own brief background hop during scanning) — this is a
/// user-chosen delay for any ordinary backgrounding.
enum LockDelayOption {
  immediate(Duration.zero),
  seconds30(Duration(seconds: 30)),
  minute1(Duration(minutes: 1)),
  minutes5(Duration(minutes: 5));

  const LockDelayOption(this.delay);

  final Duration delay;
}

class SettingsState extends Equatable {
  const SettingsState({
    this.textSize = TextSizeOption.system,
    this.lockDelay = LockDelayOption.immediate,
  });

  final TextSizeOption textSize;
  final LockDelayOption lockDelay;

  SettingsState copyWith({
    TextSizeOption? textSize,
    LockDelayOption? lockDelay,
  }) =>
      SettingsState(
        textSize: textSize ?? this.textSize,
        lockDelay: lockDelay ?? this.lockDelay,
      );

  @override
  List<Object?> get props => [textSize, lockDelay];
}

/// Owns the text-size override and app-lock delay, persisting both so the
/// choice survives a restart. Follows the same load/persist shape as
/// ThemeCubit.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _textSizeKey = 'cv_text_size';
  static const _lockDelayKey = 'cv_lock_delay';

  static SettingsState _load(SharedPreferences prefs) {
    final textSize = TextSizeOption.values.firstWhere(
      (o) => o.name == prefs.getString(_textSizeKey),
      orElse: () => TextSizeOption.system,
    );
    final lockDelay = LockDelayOption.values.firstWhere(
      (o) => o.name == prefs.getString(_lockDelayKey),
      orElse: () => LockDelayOption.immediate,
    );
    return SettingsState(textSize: textSize, lockDelay: lockDelay);
  }

  void setTextSize(TextSizeOption option) {
    _prefs.setString(_textSizeKey, option.name);
    emit(state.copyWith(textSize: option));
  }

  void setLockDelay(LockDelayOption option) {
    _prefs.setString(_lockDelayKey, option.name);
    emit(state.copyWith(lockDelay: option));
  }
}

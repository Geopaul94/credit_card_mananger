import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which palette the app is skinned with. [warm] is the cream/terracotta
/// theme; [classic] is the original indigo "Refined Fintech" theme, kept
/// selectable rather than deleted.
enum AppThemeVariant { warm, classic }

class ThemeState extends Equatable {
  const ThemeState({
    this.variant = AppThemeVariant.warm,
    this.mode = ThemeMode.system,
  });

  final AppThemeVariant variant;

  /// Light / dark / follow-system — independent of [variant], so either
  /// palette can be viewed in either brightness.
  final ThemeMode mode;

  ThemeState copyWith({AppThemeVariant? variant, ThemeMode? mode}) =>
      ThemeState(variant: variant ?? this.variant, mode: mode ?? this.mode);

  @override
  List<Object?> get props => [variant, mode];
}

/// Owns the selected theme variant and brightness mode, persisting both so
/// the choice survives a restart. Previously this cubit held only a bare
/// [ThemeMode] with no persistence at all — every relaunch silently reset to
/// light, which is fixed here as a side effect of adding the variant.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _variantKey = 'cv_theme_variant';
  static const _modeKey = 'cv_theme_mode';

  static ThemeState _load(SharedPreferences prefs) {
    final variant = AppThemeVariant.values.firstWhere(
      (v) => v.name == prefs.getString(_variantKey),
      orElse: () => AppThemeVariant.warm,
    );
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_modeKey),
      orElse: () => ThemeMode.system,
    );
    return ThemeState(variant: variant, mode: mode);
  }

  void setVariant(AppThemeVariant variant) {
    _prefs.setString(_variantKey, variant.name);
    emit(state.copyWith(variant: variant));
  }

  void setMode(ThemeMode mode) {
    _prefs.setString(_modeKey, mode.name);
    emit(state.copyWith(mode: mode));
  }

  /// Convenience for the existing light/dark switch UI.
  void setDarkMode(bool enabled) =>
      setMode(enabled ? ThemeMode.dark : ThemeMode.light);
}

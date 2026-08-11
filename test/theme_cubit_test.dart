// Tests for theme persistence. Previously ThemeCubit held a bare ThemeMode
// with no persistence at all — every relaunch silently reset to light. That
// bug is fixed here as part of adding the variant, so these tests cover both.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:credit_cards/core/theme/theme_cubit.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeCubit defaults', () {
    test('starts on the warm variant and system brightness when nothing is saved',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(prefs);
      expect(cubit.state.variant, AppThemeVariant.warm);
      expect(cubit.state.mode, ThemeMode.system);
    });
  });

  group('ThemeCubit persistence', () {
    test('setVariant is readable by a cubit created afterwards', () async {
      final prefs = await SharedPreferences.getInstance();
      ThemeCubit(prefs).setVariant(AppThemeVariant.classic);

      final reopened = ThemeCubit(prefs);
      expect(reopened.state.variant, AppThemeVariant.classic);
    });

    test('setMode is readable by a cubit created afterwards', () async {
      final prefs = await SharedPreferences.getInstance();
      ThemeCubit(prefs).setMode(ThemeMode.dark);

      final reopened = ThemeCubit(prefs);
      expect(reopened.state.mode, ThemeMode.dark);
    });

    test('setDarkMode(true/false) maps to dark/light, not system', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(prefs);

      cubit.setDarkMode(true);
      expect(cubit.state.mode, ThemeMode.dark);

      cubit.setDarkMode(false);
      expect(cubit.state.mode, ThemeMode.light);
    });

    test('variant and mode persist independently of each other', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(prefs);

      cubit.setVariant(AppThemeVariant.classic);
      cubit.setMode(ThemeMode.dark);

      final reopened = ThemeCubit(prefs);
      expect(reopened.state.variant, AppThemeVariant.classic);
      expect(reopened.state.mode, ThemeMode.dark);
    });

    test('garbage stored under the keys falls back to the defaults', () async {
      SharedPreferences.setMockInitialValues({
        'cv_theme_variant': 'not_a_real_variant',
        'cv_theme_mode': 'not_a_real_mode',
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(prefs);

      expect(cubit.state.variant, AppThemeVariant.warm);
      expect(cubit.state.mode, ThemeMode.system);
    });
  });
}

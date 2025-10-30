import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/di_init.dart';

final themeProvider = AsyncNotifierProvider<ThemeProvider, ThemeMode>(
  ThemeProvider.new,
);

class ThemeProvider extends AsyncNotifier<ThemeMode> {
  @override
  FutureOr<ThemeMode> build() async {
    state = const AsyncValue.loading();
    try {
      final prefs = getIt.get<PreferencesService>();
      String? themeMode = prefs.get(AppPreferenceKeys.themeMode);
      if (themeMode == 'light') {
        state = const AsyncData(ThemeMode.light);
        return ThemeMode.light;
      } else if (themeMode == 'dark') {
        state = const AsyncData(ThemeMode.dark);
        return ThemeMode.dark;
      } else {
        state = const AsyncData(ThemeMode.system);
        return ThemeMode.system;
      }
    } catch (e) {
      state = AsyncData(ThemeMode.system);
      return ThemeMode.system;
    }
  }

  /// Сохраняет текущую тему в SharedPreferences
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = getIt.get<PreferencesService>();
      if (themeMode == ThemeMode.light) {
        await prefs.set(AppPreferenceKeys.themeMode, 'light');
      } else if (themeMode == ThemeMode.dark) {
        await prefs.set(AppPreferenceKeys.themeMode, 'dark');
      } else {
        await prefs.set(AppPreferenceKeys.themeMode, 'system');
      }
    } catch (e) {
      // logError(
      //   'Failed to save theme: $e',
      //   tag: 'Theme',
      //   stackTrace: stackTrace,
      // );
    }
  }

  Future<void> setLightTheme() async {
    state = AsyncData(ThemeMode.light);
    // logInfo('Theme changed to light', tag: 'Theme');
    await _saveTheme(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    state = AsyncData(ThemeMode.dark);
    // logInfo('Theme changed to dark', tag: 'Theme');
    await _saveTheme(ThemeMode.dark);
  }

  Future<void> setSystemTheme() async {
    state = AsyncData(ThemeMode.system);
    // logInfo('Theme changed to system', tag: 'Theme');
    await _saveTheme(ThemeMode.system);
  }

  Future<void> toggleTheme() async {
    final currentTheme = state.value ?? ThemeMode.system;
    switch (currentTheme) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        // При системной теме переключаемся на противоположную
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
          await setLightTheme();
        } else {
          await setDarkTheme();
        }
        break;
    }
  }
}

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Цветовые схемы приложения
abstract final class AppColors {
  /// Светлая цветовая схема
  static const FlexSchemeColor lightColors = FlexSchemeColor(
    primary: Color(0xFF005BFF),
    primaryContainer: Color(0xFF005BFF),
    secondary: Color(0xFFE2E2E2),
    secondaryContainer: Color(0xFFE2E2E2),
    tertiary: Color(0xFFF0F1F1),
    tertiaryContainer: Color(0xFFF1F1F1),
    appBarColor: Color(0xFFE2E2E2),
    error: Color.fromARGB(255, 255, 48, 48),
    errorContainer: Color(0xFFFF1744),
  );

  /// Тёмная цветовая схема
  static const FlexSchemeColor darkColors = FlexSchemeColor(
    primary: Color(0xFF1E6DFB),
    primaryContainer: Color(0xFF1E6DFB),
    primaryLightRef: Color(0xFF005BFF), // The color of light mode primary
    secondary: Color(0xFF292929),
    secondaryContainer: Color(0xFF292929),
    secondaryLightRef: Color(0xFFE2E2E2), // The color of light mode secondary
    tertiary: Color(0xFF414141),
    tertiaryContainer: Color(0xFF414141),
    tertiaryLightRef: Color(0xFFF0F1F1), // The color of light mode tertiary
    appBarColor: Color(0xFFE2E2E2),
    error: Color.fromARGB(255, 255, 48, 48),
    errorContainer: Color(0xFFD50000),
  );

  /// Цвет поверхности для тёмной темы
  static const Color darkSurfaceTint = Color(0xFF1E6DFB);

  /// Основной цвет приложения
  static const Color darkSurface = Color(0xFF0e0e0e);

  //primary: Color(0xFF005BFF),

  static const Color primary = Color(0xFF1E6DFB);
}

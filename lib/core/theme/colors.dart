import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Цветовые схемы приложения
abstract final class AppColors {
  /// Светлая цветовая схема
  static const FlexSchemeColor lightColors = FlexSchemeColor(
    primary: Color(0xFF3A51FC),
    primaryContainer: Color(0xFF3A51FC),
    secondary: Color(0xFFEDEDED),
    secondaryContainer: Color(0xFFEDEDED),
    tertiary: Color(0xFFEDEDED),
    tertiaryContainer: Color(0xFFEDEDED),
    appBarColor: Color(0xFFEDEDED),
    error: Color(0xFFDE372F),
    errorContainer: Color(0xFFD50000),
  );

  /// Тёмная цветовая схема
  static const FlexSchemeColor darkColors = FlexSchemeColor(
    primary: Color(0xFF3A51FC),
    primaryContainer: Color(0xFF3A51FC),
    primaryLightRef: Color(0xFF3A51FC), // The color of light mode primary
    secondary: Color(0xFF2C2C2C),
    secondaryContainer: Color(0xFF2C2C2C),
    secondaryLightRef: Color(0xFFEDEDED), // The color of light mode secondary
    tertiary: Color(0xFF2C2C2C),
    tertiaryContainer: Color(0xFF2C2C2C),
    tertiaryLightRef: Color(0xFFEDEDED), // The color of light mode tertiary
    appBarColor: Color(0xFFEDEDED),
    error: Color(0xFFE53935),
    errorContainer: Color(0xFFB81D28),
  );

  /// Цвет поверхности для тёмной темы
  static const Color darkSurfaceTint = Color(0xFF3A51FC);

  /// Основной цвет приложения
  static const Color darkSurface = Color(0xFF0e0e0e);

  //primary: Color(0xFF005BFF),

  static const Color primary = Color(0xFF3A51FC);
}

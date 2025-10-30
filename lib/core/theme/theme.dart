import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'button_themes.dart';
import 'colors.dart';
import 'component_themes.dart';

final visualDensity = VisualDensity.comfortable;

abstract final class AppTheme {
  static ThemeData _withNunito(ThemeData theme) {
    return theme.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(theme.textTheme),
    );
  }

  // LIGHT THEME
  static ThemeData light(BuildContext context) {
    final base = FlexThemeData.light(
      colors: AppColors.lightColors,
      useMaterial3ErrorColors: true,
      swapLegacyOnMaterial3: true,
      subThemesData: ComponentThemes.lightSubThemes,
      visualDensity: visualDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      useMaterial3: true,
      transparentStatusBar: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      error: Color(0xFFDE372F),
      errorContainer: Color(0xFFD50000),
    );

    return _withNunito(
      base.copyWith(
        elevatedButtonTheme: ButtonThemes.adaptiveElevatedButtonTheme(
          context,
          base,
        ),
        filledButtonTheme: ButtonThemes.adaptiveFilledButtonTheme(
          context,
          base,
        ),
        outlinedButtonTheme: ButtonThemes.adaptiveOutlinedButtonTheme(
          context,
          base,
        ),
        textButtonTheme: ButtonThemes.adaptiveTextButtonTheme(context, base),
        listTileTheme: ComponentThemes.adaptiveListTileTheme(),
      ),
    );
  }

  // DARK THEME
  static ThemeData dark(BuildContext context) {
    final base = FlexThemeData.dark(
      colors: AppColors.darkColors,
      useMaterial3ErrorColors: true,
      swapLegacyOnMaterial3: true,
      surfaceTint: AppColors.darkSurfaceTint,
      subThemesData: ComponentThemes.darkSubThemes,
      visualDensity: visualDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      useMaterial3: true,
      transparentStatusBar: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      error: Color(0xFFE53935),
      errorContainer: Color(0xFFB81D28),
    );

    return _withNunito(
      base.copyWith(
        elevatedButtonTheme: ButtonThemes.adaptiveElevatedButtonTheme(
          context,
          base,
        ),
        filledButtonTheme: ButtonThemes.adaptiveFilledButtonTheme(
          context,
          base,
        ),
        outlinedButtonTheme: ButtonThemes.adaptiveOutlinedButtonTheme(
          context,
          base,
        ),
        textButtonTheme: ButtonThemes.adaptiveTextButtonTheme(context, base),
        listTileTheme: ComponentThemes.adaptiveListTileTheme(),
      ),
    );
  }
}

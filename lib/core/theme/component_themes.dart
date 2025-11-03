import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

/// Темы компонентов приложения
abstract final class ComponentThemes {
  /// Адаптивная тема для ListTile
  static ListTileThemeData adaptiveListTileTheme() {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  /// Базовые подтемы для светлой темы
  static const FlexSubThemesData lightSubThemes = FlexSubThemesData(
    // interactionEffects: true,
    // tintedDisabledControls: true,
    useM2StyleDividerInM3: true,
    defaultRadius: defaultBorderRadius,
    switchSchemeColor: SchemeColor.primary,
    switchThumbSchemeColor: SchemeColor.onPrimary,
    inputDecoratorIsFilled: true,
    alignedDropdown: true,
    tooltipSchemeColor: SchemeColor.secondary,
    tooltipOpacity: 0.9,
    // dialogRadius: 31.0,
    timePickerElementRadius: defaultBorderRadius,
    snackBarElevation: 4,
    snackBarBackgroundSchemeColor: SchemeColor.secondary,
    snackBarActionSchemeColor: SchemeColor.primary,
    bottomAppBarHeight: 64,
    tabBarDividerColor: Color(0x00000000),
    tabBarIndicatorAnimation: TabIndicatorAnimation.elastic,
    drawerIndicatorSchemeColor: SchemeColor.secondary,
    searchBarRadius: defaultBorderRadius,
    searchViewRadius: defaultBorderRadius,
    navigationRailUseIndicator: true,
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    scaffoldBackgroundBaseColor: FlexScaffoldBaseColor.surface,
    appBarTitleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bottomSheetModalBackgroundColor: SchemeColor.surfaceContainerLow,
    dialogBackgroundSchemeColor: SchemeColor.surfaceContainerLow,
  );

  /// Базовые подтемы для тёмной темы
  static const FlexSubThemesData darkSubThemes = FlexSubThemesData(
    // interactionEffects: true,
    // tintedDisabledControls: true,
    blendOnColors: true,
    useM2StyleDividerInM3: true,
    defaultRadius: defaultBorderRadius,
    switchSchemeColor: SchemeColor.primary,
    switchThumbSchemeColor: SchemeColor.onPrimary,
    inputDecoratorIsFilled: true,
    alignedDropdown: true,
    tooltipSchemeColor: SchemeColor.secondary,
    tooltipOpacity: 0.9,
    // dialogRadius: 31.0,
    timePickerElementRadius: defaultBorderRadius,
    snackBarElevation: 4,
    snackBarBackgroundSchemeColor: SchemeColor.secondary,
    snackBarActionSchemeColor: SchemeColor.primary,
    bottomAppBarHeight: 64,
    tabBarDividerColor: Color(0x00000000),
    tabBarIndicatorAnimation: TabIndicatorAnimation.elastic,
    drawerIndicatorSchemeColor: SchemeColor.secondary,
    searchBarRadius: defaultBorderRadius,
    searchViewRadius: defaultBorderRadius,
    navigationRailUseIndicator: true,

    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    scaffoldBackgroundBaseColor: FlexScaffoldBaseColor.surface,
    appBarTitleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bottomSheetModalBackgroundColor: SchemeColor.surfaceContainerLow,
    dialogBackgroundSchemeColor: SchemeColor.surfaceContainerLow,
  );
}

enum ButtonSize { small, medium, large }

enum ButtonType { elevated, filled, text, outlined }

ButtonStyle buttonStyle(
  BuildContext context, {
  required ButtonType type,
  required ButtonSize size,
}) {
  // Берём базовый стиль из темы в зависимости от типа кнопки
  final baseStyle =
      switch (type) {
        ButtonType.elevated => ElevatedButtonTheme.of(context).style,
        ButtonType.filled => FilledButtonTheme.of(context).style,
        ButtonType.text => TextButtonTheme.of(context).style,
        ButtonType.outlined => OutlinedButtonTheme.of(context).style,
      } ??
      const ButtonStyle();

  // Размеры
  final (padding, fontSize, minSize) = switch (size) {
    ButtonSize.small => (
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      12.0,
      const Size(64, 32),
    ),
    ButtonSize.medium => (
      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      14.0,
      const Size(88, 40),
    ),
    ButtonSize.large => (
      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      16.0,
      const Size(120, 48),
    ),
  };

  return baseStyle.copyWith(
    padding: WidgetStateProperty.all(padding),
    textStyle: WidgetStateProperty.all(
      Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: fontSize),
    ),
    minimumSize: WidgetStateProperty.all(minSize),
  );
}

import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

/// Показывает bottom sheet на мобильных устройствах и modal dialog на десктопе
/// используя только нативные компоненты Flutter.
///
/// Пример использования:
/// ```dart
/// UniversalModal.show(
///   context: context,
///   builder: (context) => MyContent(),
/// );
/// ```
class UniversalModal {
  /// Показывает bottom sheet или modal в зависимости от платформы
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    BoxConstraints? constraints,
    bool isScrollControlled = false,
    bool useRootNavigator = true,
    bool useSafeArea = true,
    bool showDragHandle = true,
  }) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    if (isMobile) {
      return _showBottomSheet<T>(
        context: context,
        useSafeArea: useSafeArea,
        builder: builder,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        constraints: constraints,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        showDragHandle: showDragHandle,
      );
    } else {
      return _showDialog<T>(
        context: context,
        builder: builder,
        isDismissible: isDismissible,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        useSafeArea: useSafeArea,
        constraints: constraints,
        useRootNavigator: useRootNavigator,
      );
    }
  }

  static Future<T?> _showBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required bool isDismissible,
    required bool enableDrag,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    BoxConstraints? constraints,
    bool useSafeArea = true,
    bool showDragHandle = true,
    required bool isScrollControlled,
    required bool useRootNavigator,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,

      showDragHandle: showDragHandle,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      useSafeArea: useSafeArea,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
      constraints: constraints,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
    );
  }

  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required bool isDismissible,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    BoxConstraints? constraints,
    bool useSafeArea = true,
    required bool useRootNavigator,
  }) {
    return showDialog<T>(
      context: context,
      useSafeArea: useSafeArea,
      barrierDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      builder: (context) => Dialog(
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints:
              constraints ??
              const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: builder(context),
        ),
      ),
    );
  }
}

/// Обёртка для контента модального окна с типовым паддингом и скроллом
class UniversalModalContent extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const UniversalModalContent({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.all(
      UniversalPlatform.isMobile ? 16.0 : 24.0,
    );

    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: padding ?? defaultPadding,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.titleLarge!,
              child: title!,
            ),
          ),
        Flexible(
          fit: shrinkWrap ? FlexFit.loose : FlexFit.tight,
          child: SingleChildScrollView(
            padding: padding ?? defaultPadding,
            child: child,
          ),
        ),
        if (actions != null && actions!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: defaultPadding.horizontal / 2,
              right: defaultPadding.horizontal / 2,
              bottom: defaultPadding.vertical / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

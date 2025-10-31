import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/theme/index.dart';
// import 'package:hoplixi/shared/widgets/close_database_button.dart';
// import 'package:hoplixi/app/constants/main_constants.dart';
// import 'package:hoplixi/app/theme/index.dart';
// import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
// import 'package:hoplixi/hoplixi_store/providers/providers.dart';
// import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  final BoxConstraints constraints = const BoxConstraints(
    maxHeight: 40,
    maxWidth: 40,
  );

  @override
  Widget build(BuildContext context) {
    // final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    // final closeDbTimer = ref.watch(appInactivityTimeoutProvider);
    final labelState = ref.watch(labelStateProvider);
    return DragToMoveArea(
      child: Container(
        height: 40,
        // color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            labelState.hidden
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      spacing: 4,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image(
                            image: AssetImage('assets/logo/logo.png'),
                          ),
                        ),
                        Text(
                          labelState.label,
                          style: TextStyle(
                            color:
                                labelState.color ??
                                (Theme.of(context).colorScheme.brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal,
                            letterSpacing: 0.0,
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,

                spacing: 4,

                children: [
                  // if (isDatabaseOpen && closeDbTimer > 0 && closeDbTimer <= 60)
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 4,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: Colors.red.withValues(alpha: 0.1),
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     child: Text(
                  //       'Авто-закрытие через $closeDbTimer с',
                  //       style: TextStyle(
                  //         color: Theme.of(context).colorScheme.onSurfaceVariant,
                  //         fontSize: 12,
                  //         fontWeight: FontWeight.normal,
                  //         fontStyle: FontStyle.normal,
                  //         letterSpacing: 0.0,
                  //         decoration: TextDecoration.none,
                  //       ),
                  //     ),
                  //   ),
                  // CloseDatabaseButton(),
                  ThemeSwitcher(size: 26),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    icon: Icon(Icons.remove, size: 20),
                    tooltip: 'Свернуть',
                    constraints: constraints,
                    onPressed: () => windowManager.minimize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Развернуть',
                    constraints: constraints,
                    icon: Icon(Icons.minimize, size: 20),
                    onPressed: () => windowManager.maximize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Закрыть',
                    hoverColor: Colors.red,
                    constraints: constraints,
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () async => {
                      if (UniversalPlatform.isDesktop)
                        await windowManager.hide(),

                      // await windowManager.close(),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class LabelState {
  final String label;
  final Color? color;
  final Widget? icon;
  final bool loading;
  final bool hidden;

  const LabelState({
    required this.label,
    this.loading = false,
    this.hidden = false,
    this.color,
    this.icon,
  });

  LabelState copyWith({
    String? label,
    Color? color,
    Widget? icon,
    bool? loading,
    bool? hidden,
  }) {
    return LabelState(
      label: label ?? this.label,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      loading: loading ?? this.loading,
      hidden: hidden ?? this.hidden,
    );
  }
}

class LabelStateNotifier extends Notifier<LabelState> {
  @override
  LabelState build() {
    return const LabelState(label: MainConstants.appName);
  }

  void updateLabel(String newLabel) {
    state = state.copyWith(label: newLabel);
  }

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }

  void setHidden(bool hidden) {
    state = state.copyWith(hidden: hidden);
  }

  void updateColor(Color? color) {
    state = state.copyWith(color: color);
  }

  void updateIcon(Widget? icon) {
    state = state.copyWith(icon: icon);
  }
}

final labelStateProvider = NotifierProvider<LabelStateNotifier, LabelState>(
  LabelStateNotifier.new,
);

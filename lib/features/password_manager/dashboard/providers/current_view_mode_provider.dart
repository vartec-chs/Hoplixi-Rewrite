import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { list, grid }

/// Провайдер для управления режимом отображения списка (список/сетка)
final currentViewModeProvider = NotifierProvider<ViewModeNotifier, ViewMode>(
  ViewModeNotifier.new,
);

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() {
    return ViewMode.list;
  }

  void setViewMode(ViewMode mode) {
    state = mode;
  }

  void toggleViewMode() {
    state = state == ViewMode.list ? ViewMode.grid : ViewMode.list;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние sidebar в dashboard
class DashboardSidebarState {
  final Widget? content;

  const DashboardSidebarState({this.content});

  bool get isOpen => content != null;

  DashboardSidebarState copyWith({Widget? Function()? content}) {
    return DashboardSidebarState(
      content: content != null ? content() : this.content,
    );
  }
}

/// Notifier для управления sidebar
class DashboardSidebarNotifier extends Notifier<DashboardSidebarState> {
  @override
  DashboardSidebarState build() {
    return const DashboardSidebarState();
  }

  /// Открыть sidebar с содержимым
  void open(Widget content) {
    state = DashboardSidebarState(content: content);
  }

  /// Закрыть sidebar
  void close() {
    state = const DashboardSidebarState();
  }
}

/// Провайдер для управления sidebar
final dashboardSidebarProvider =
    NotifierProvider<DashboardSidebarNotifier, DashboardSidebarState>(
      DashboardSidebarNotifier.new,
    );

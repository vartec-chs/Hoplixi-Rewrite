import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';

/// Пример кнопки для закрытия sidebar из любого места приложения
class CloseSidebarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;

  const CloseSidebarButton({super.key, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon ?? Icons.close),
      tooltip: label ?? 'Закрыть',
      onPressed: () {
        // Безопасно закрываем sidebar через глобальный ключ
        final state = dashboardSidebarKey.currentState;
        if (state != null && state is DashboardLayoutState) {
          state.closeSidebar();
        }
      },
    );
  }
}

/// Пример кнопки для переключения состояния sidebar
class ToggleSidebarButton extends StatelessWidget {
  const ToggleSidebarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Переключить sidebar',
      onPressed: () {
        final state = dashboardSidebarKey.currentState;
        if (state != null && state is DashboardLayoutState) {
          state.toggleSidebar();
        }
      },
    );
  }
}

/// Пример виджета, который показывает состояние sidebar
class SidebarStatusIndicator extends StatefulWidget {
  const SidebarStatusIndicator({super.key});

  @override
  State<SidebarStatusIndicator> createState() => _SidebarStatusIndicatorState();
}

class _SidebarStatusIndicatorState extends State<SidebarStatusIndicator> {
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _checkSidebarStatus();
  }

  void _checkSidebarStatus() {
    final state = dashboardSidebarKey.currentState;
    if (state != null && state is DashboardLayoutState) {
      setState(() {
        _isSidebarOpen = state.isSidebarOpen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isSidebarOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _isSidebarOpen ? 'Sidebar открыт' : 'Sidebar закрыт',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// Расширение для типа State, чтобы безопасно приводить к DashboardLayoutState
extension DashboardLayoutStateExtension on State<StatefulWidget> {
  /// Проверяет, является ли этот State экземпляром DashboardLayoutState
  bool get isDashboardLayoutState => this is DashboardLayoutState;

  /// Приводит к DashboardLayoutState, если возможно
  DashboardLayoutState? get asDashboardLayoutState {
    return this is DashboardLayoutState ? this as DashboardLayoutState : null;
  }
}

/// Хелпер класс для удобной работы с sidebar
class SidebarController {
  /// Закрывает sidebar, если он доступен
  static void close() {
    final state = dashboardSidebarKey.currentState?.asDashboardLayoutState;
    state?.closeSidebar();
  }

  /// Открывает sidebar, если он доступен
  static void open() {
    final state = dashboardSidebarKey.currentState?.asDashboardLayoutState;
    state?.openSidebar();
  }

  /// Переключает состояние sidebar
  static void toggle() {
    final state = dashboardSidebarKey.currentState?.asDashboardLayoutState;
    state?.toggleSidebar();
  }

  /// Проверяет, открыт ли sidebar
  static bool get isOpen {
    final state = dashboardSidebarKey.currentState?.asDashboardLayoutState;
    return state?.isSidebarOpen ?? false;
  }

  /// Проверяет, доступен ли sidebar
  static bool get isAvailable {
    return dashboardSidebarKey.currentState?.asDashboardLayoutState != null;
  }
}

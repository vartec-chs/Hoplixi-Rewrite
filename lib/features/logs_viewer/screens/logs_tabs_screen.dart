import 'package:flutter/material.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_viewer_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/crash_reports_screen.dart';

/// Главный экран для навигации между просмотром логов и отчетами о падениях
class LogsTabsScreen extends StatefulWidget {
  const LogsTabsScreen({super.key});

  @override
  State<LogsTabsScreen> createState() => _LogsTabsScreenState();
}

class _LogsTabsScreenState extends State<LogsTabsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [LogsViewerScreen(), CrashReportsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.description), label: 'Логи'),
          NavigationDestination(icon: Icon(Icons.error), label: 'Падения'),
        ],
      ),
    );
  }
}

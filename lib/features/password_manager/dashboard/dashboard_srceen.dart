import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_sidebar_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(dashboardSidebarProvider);
    final sidebarNotifier = ref.read(dashboardSidebarProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return DashboardLayout(
            isDesktop: isDesktop,
            navigationRail: isDesktop ? _buildNavigationRail(context) : null,
            mainContent: _buildMainContent(context, ref, isDesktop),
            sidebarContent: sidebarState.content,
            onCloseSidebar: sidebarNotifier.close,
          );
        },
      ),
      extendBody: true,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) return const SizedBox.shrink();
          return _buildBottomAppBar(context);
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () => _openCreateForm(context, ref),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 4),
              Text(
                'Создать',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _handleNavigationTap(index, context, ref);
        },
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FloatingActionButton(
            elevation: 0,
            onPressed: () => _openCreateForm(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Главная'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('Категории'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: Text('Поиск'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Настройки'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 70,

      notchMargin: 5,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildBottomNavIconButton(
            context,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Главная',
            index: 0,
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            label: 'Категории',
            index: 1,
          ),
          const SizedBox(width: 40), // Место для FAB по центру
          _buildBottomNavIconButton(
            context,
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Поиск',
            index: 2,
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Настройки',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIconButton(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _handleNavigationTap(index, context, ref);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigationTap(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        // Главная - ничего не делаем, уже на главной
        break;
      case 1:
        _openCategoriesForm(context, ref);
        break;
      case 2:
        _openSearchForm(context, ref);
        break;
      case 3:
        // Открыть настройки
        break;
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
  ) {
    return CustomScrollView(
      slivers: [
        // AppBar с поиском и вкладками
        DashboardSliverAppBar(
          title: 'Dashboard',
          expandedHeight: 168,
          pinned: isDesktop,
          floating: true,
          snap: true,
          onMenuPressed: isDesktop
              ? null
              : () {
                  // Открыть drawer на мобильных устройствах
                },
          additionalActions: [
            if (isDesktop)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Настройки
                },
                tooltip: 'Настройки',
              ),
          ],
        ),

        // Padding сверху
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Главный контент
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Главная панель',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выберите действие',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _ActionCard(
                          icon: Icons.add_circle_outline,
                          title: 'Создать запись',
                          description: 'Добавить новую запись',
                          onTap: () => _openCreateForm(context, ref),
                        ),
                        _ActionCard(
                          icon: Icons.folder_outlined,
                          title: 'Категории',
                          description: 'Управление категориями',
                          onTap: () => _openCategoriesForm(context, ref),
                        ),
                        _ActionCard(
                          icon: Icons.search,
                          title: 'Поиск',
                          description: 'Найти записи',
                          onTap: () => _openSearchForm(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openCreateForm(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final sidebarNotifier = ref.read(dashboardSidebarProvider.notifier);

    if (isDesktop) {
      // Открыть в sidebar на больших экранах
      sidebarNotifier.open(
        _buildFormContent(
          context,
          'Создать запись',
          'Форма для создания новой записи',
        ),
      );
    } else {
      // Открыть на новой странице на маленьких экранах
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Создать запись')),
            body: _buildFormContent(
              context,
              'Создать запись',
              'Форма для создания новой записи',
            ),
          ),
        ),
      );
    }
  }

  void _openCategoriesForm(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final sidebarNotifier = ref.read(dashboardSidebarProvider.notifier);

    if (isDesktop) {
      sidebarNotifier.open(
        _buildFormContent(context, 'Категории', 'Управление категориями'),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Категории')),
            body: _buildFormContent(
              context,
              'Категории',
              'Управление категориями',
            ),
          ),
        ),
      );
    }
  }

  void _openSearchForm(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final sidebarNotifier = ref.read(dashboardSidebarProvider.notifier);

    if (isDesktop) {
      sidebarNotifier.open(
        _buildFormContent(context, 'Поиск', 'Поиск записей'),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Поиск')),
            body: _buildFormContent(context, 'Поиск', 'Поиск записей'),
          ),
        ),
      );
    }
  }

  Widget _buildFormContent(
    BuildContext context,
    String title,
    String description,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  // color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Здесь будет содержимое формы
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenPaddingValue),
                child: Center(
                  child: Text(
                    'Форма в разработке',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

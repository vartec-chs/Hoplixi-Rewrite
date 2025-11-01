import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_sidebar_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarState = ref.watch(dashboardSidebarProvider);
    final sidebarNotifier = ref.read(dashboardSidebarProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return DashboardLayout(
            mainContent: _buildMainContent(context, ref, isDesktop),
            sidebarContent: sidebarState.content,
            onCloseSidebar: sidebarNotifier.close,
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // AppBar встроен в main content
            SliverAppBar(
              title: const Text('Dashboard'),
              floating: true,
              pinned: true,
              snap: true,
              actions: [
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
              // hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),

        // FloatingActionButton только в main content
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openCreateForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Создать'),
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
        // Отслеживаем изменения темы для автоматического перестроения UI
        ref.watch(themeProvider);
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

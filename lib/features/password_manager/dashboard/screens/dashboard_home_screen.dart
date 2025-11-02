import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // AppBar с поиском и вкладками
        DashboardSliverAppBar(
          title: 'Dashboard',
          expandedHeight: 168,
          pinned: MediaQuery.of(context).size.width >= 900,
          floating: true,
          snap: true,
          onMenuPressed: MediaQuery.of(context).size.width >= 900
              ? null
              : () {
                  // Открыть drawer на мобильных
                },
          additionalActions: [
            if (MediaQuery.of(context).size.width >= 900)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Дополнительные действия
                },
              ),
          ],
        ),

        // Padding сверху
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Быстрые действия
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Быстрые действия',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Добавить запись',
                      description: 'Создать новую запись пароля',
                      onTap: () {
                        // Добавить логику создания
                      },
                    ),
                    _ActionCard(
                      icon: Icons.folder_outlined,
                      title: 'Категории',
                      description: 'Управление категориями',
                      onTap: () {
                        // Открыть категории
                      },
                    ),
                    _ActionCard(
                      icon: Icons.security_outlined,
                      title: 'Безопасность',
                      description: 'Проверить безопасность паролей',
                      onTap: () {
                        // Открыть проверку безопасности
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Заголовок последних записей
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Последние записи',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Список последних записей
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text('Запись ${index + 1}'),
                  subtitle: Text('Описание записи ${index + 1}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Показать меню действий
                    },
                  ),
                ),
              );
            }, childCount: 5),
          ),
        ),

        // Padding снизу
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

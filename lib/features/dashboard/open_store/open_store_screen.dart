import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/dashboard/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/dashboard/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/features/dashboard/open_store/widgets/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/titlebar.dart';

class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

/// Экран открытия хранилища
class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTitleBarLabel();
    });
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(openStoreFormProvider);
    final notifier = ref.read(openStoreFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Открыть хранилище'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final state = asyncState.value;
            if (state != null && state.selectedStorage != null) {
              notifier.cancelSelection();
              return;
            }
            ref
                .read(titlebarStateProvider.notifier)
                .setBackgroundTransparent(true);
            context.pop();
            // context.pop()
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: asyncState.isLoading
                ? null
                : () => notifier.loadStorages(),
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _buildBody(context, state, notifier, ref),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Инициализация...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка инициализации',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(openStoreFormProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
    WidgetRef ref,
  ) {
    // Показываем индикатор загрузки
    if (state.isLoading && state.storages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка хранилищ...'),
          ],
        ),
      );
    }

    // Показываем ошибку если есть
    if (state.error != null && state.storages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => notifier.loadStorages(),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Если хранилище выбрано - показываем форму пароля
    if (state.selectedStorage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),

          child: SingleChildScrollView(
            child: PasswordForm(
              storage: state.selectedStorage!,
              password: state.password,
              passwordError: state.passwordError,
              isOpening: state.isOpening,
              onPasswordChanged: notifier.updatePassword,
              onSubmit: () => _handleOpenStorage(context, notifier, ref),
              onCancel: notifier.cancelSelection,
            ),
          ),
        ),
      );
    }

    // Показываем список хранилищ
    return Column(
      children: [
        if (state.error != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed: () {
                    // Очистить ошибку через новый метод если добавите
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: StorageList(
            storages: state.storages,
            selectedStorage: state.selectedStorage,
            onStorageSelected: notifier.selectStorage,
          ),
        ),
      ],
    );
  }

  Future<void> _handleOpenStorage(
    BuildContext context,
    OpenStoreFormNotifier notifier,
    WidgetRef ref,
  ) async {
    final success = await notifier.openStorage();

    if (success && context.mounted) {
      Toaster.success(
        context: context,
        title: 'Успешно',
        description: 'Хранилище открыто',
      );
      context.go(AppRoutesPaths.home);
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
    } else if (!success && context.mounted) {
      final asyncState = ref.read(openStoreFormProvider);
      final state = asyncState.value;
      if (state?.error != null) {
        Toaster.error(
          context: context,
          title: 'Ошибка',
          description: state!.error!,
        );
      }
    }
  }
}

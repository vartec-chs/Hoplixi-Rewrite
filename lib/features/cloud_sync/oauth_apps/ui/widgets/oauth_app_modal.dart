import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/providers/oauth_apps_provider.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

const _uuid = Uuid();

/// Показать модальное окно для создания или редактирования OAuth приложения
void showOAuthAppModal({required BuildContext context, OauthApps? app}) {
  // Не показываем модальное окно для встроенных приложений
  if (app?.isBuiltin == true) {
    return;
  }

  WoltModalSheet.show<void>(
    context: context,

    pageListBuilder: (modalSheetContext) {
      return [_buildFormPage(modalSheetContext, app)];
    },
  );
}

SliverWoltModalSheetPage _buildFormPage(BuildContext context, OauthApps? app) {
  final isEdit = app != null;

  return SliverWoltModalSheetPage(
    pageTitle: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        isEdit ? 'Редактировать приложение' : 'Новое приложение',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    leadingNavBarWidget: ModalSheetCloseButton(),
    mainContentSliversBuilder: (context) => [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        sliver: SliverToBoxAdapter(child: _OAuthAppForm(app: app)),
      ),
    ],
  );
}

class _OAuthAppForm extends ConsumerStatefulWidget {
  final OauthApps? app;

  const _OAuthAppForm({this.app});

  @override
  ConsumerState<_OAuthAppForm> createState() => _OAuthAppFormState();
}

class _OAuthAppFormState extends ConsumerState<_OAuthAppForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  late OauthAppsType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.app?.name ?? '');
    _clientIdController = TextEditingController(
      text: widget.app?.clientId ?? '',
    );
    _clientSecretController = TextEditingController(
      text: widget.app?.clientSecret ?? '',
    );
    _selectedType = widget.app?.type ?? OauthAppsType.google;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.app != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Тип приложения
          Text(
            'Тип приложения',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<OauthAppsType>(
            segments: [
              ButtonSegment(
                value: OauthAppsType.google,
                label: const Text('Google'),
                icon: const Icon(Icons.g_mobiledata),
              ),
              ButtonSegment(
                value: OauthAppsType.dropbox,
                label: const Text('Dropbox'),
                icon: const Icon(Icons.cloud_queue),
              ),
              ButtonSegment(
                value: OauthAppsType.onedrive,
                label: const Text('OneDrive'),
                icon: const Icon(Icons.cloud_outlined),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<OauthAppsType> selected) {
              setState(() {
                _selectedType = selected.first;
              });
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: 8),
          SegmentedButton<OauthAppsType>(
            segments: [
              ButtonSegment(
                value: OauthAppsType.yandex,
                label: const Text('Yandex'),
                icon: const Icon(Icons.language),
              ),
              ButtonSegment(
                value: OauthAppsType.other,
                label: const Text('Другое'),
                icon: const Icon(Icons.extension),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<OauthAppsType> selected) {
              setState(() {
                _selectedType = selected.first;
              });
            },
            showSelectedIcon: false,
          ),

          const SizedBox(height: 24),

          // Название
          TextFormField(
            controller: _nameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Например: Мой Google Drive',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите название приложения';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 16),

          // Client ID
          TextFormField(
            controller: _clientIdController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Client ID',
              hintText: 'Введите Client ID',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите Client ID';
              }
              return null;
            },
            keyboardType: TextInputType.text,
          ),

          const SizedBox(height: 16),

          // Client Secret (опционально)
          TextFormField(
            controller: _clientSecretController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Client Secret (опционально)',
              hintText: 'Введите Client Secret',
            ),
            obscureText: true,
            keyboardType: TextInputType.text,
          ),

          const SizedBox(height: 32),

          // Кнопка сохранения
          FilledButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Сохранить' : 'Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final app = OauthApps(
        id: widget.app?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim().isEmpty
            ? null
            : _clientSecretController.text.trim(),
        isBuiltin: widget.app?.isBuiltin ?? false,
      );

      final notifier = ref.read(oauthAppsProvider.notifier);

      if (widget.app != null) {
        await notifier.updateApp(app);
        if (mounted) {
          Toaster.success(
            title: 'Приложение обновлено',
            description: 'Изменения успешно сохранены',
          );
        }
      } else {
        await notifier.createApp(app);
        if (mounted) {
          Toaster.success(
            title: 'Приложение создано',
            description: 'Новое OAuth приложение добавлено',
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Toaster.error(title: 'Ошибка', description: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

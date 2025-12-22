import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/forms/note_form/models/note_form_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/sidebar_controller.dart';
import 'package:hoplixi/shared/ui/button.dart';
import '../providers/note_form_provider.dart';
import '../widgets/note_metadata_modal.dart';

/// Экран формы создания/редактирования заметки
/// Основной интерфейс - QuillEditor для редактирования контента
/// При сохранении открывается модальное окно для редактирования метаданных
class NoteFormScreen extends ConsumerStatefulWidget {
  const NoteFormScreen({super.key, this.noteId});

  /// ID заметки для редактирования (null = режим создания)
  final String? noteId;

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  late final QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isInitialized = false;

  bool get isEditMode => widget.noteId != null;

  @override
  void initState() {
    super.initState();

    // Инициализируем пустой контроллер
    _quillController = QuillController.basic(
      config: const QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(enableExternalRichPaste: true),
      ),
    );

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(noteFormProvider.notifier);
      if (widget.noteId != null) {
        notifier.initForEdit(widget.noteId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  /// Синхронизировать контроллер с состоянием провайдера
  void _syncControllerWithState(NoteFormState state) {
    if (!_isInitialized &&
        state.deltaJson.isNotEmpty &&
        state.deltaJson != '[]') {
      try {
        final deltaJson = jsonDecode(state.deltaJson) as List<dynamic>;
        _quillController.document = Document.fromJson(deltaJson);
        _isInitialized = true;
      } catch (e) {
        // Если не удалось распарсить, оставляем пустой документ
        _isInitialized = true;
      }
    }
  }

  /// Обновить состояние провайдера из контроллера
  void _updateStateFromController() {
    ref.read(noteFormProvider.notifier).updateFromController(_quillController);
  }

  /// Показать модальное окно и сохранить заметку
  void _handleSave() async {
    // Сначала обновляем контент из редактора
    _updateStateFromController();

    final state = ref.read(noteFormProvider);

    // Проверяем, что контент не пустой
    if (state.content.trim().isEmpty) {
      Toaster.warning(
        title: 'Пустая заметка',
        description: 'Добавьте содержание перед сохранением',
      );
      return;
    }

    // Показываем модальное окно для редактирования метаданных
    final result = await showNoteMetadataModal(
      context,
      ref: ref,
      isEditMode: isEditMode,
      onSave: () async {
        final success = await ref.read(noteFormProvider.notifier).save();

        if (!mounted) return;

        if (success) {
          Toaster.success(
            title: isEditMode ? 'Заметка обновлена' : 'Заметка создана',
            description: 'Изменения успешно сохранены',
          );
          context.pop(true);
        } else {
          Toaster.error(
            title: 'Ошибка сохранения',
            description: 'Не удалось сохранить заметку',
          );
        }
      },
    );

    // Если пользователь отменил модальное окно
    if (result == false) {
      // Ничего не делаем, остаемся на экране редактирования
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(noteFormProvider);

    // Синхронизируем контроллер с состоянием при загрузке данных редактирования
    if (state.isEditMode && !state.isLoading) {
      _syncControllerWithState(state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Редактировать заметку' : 'Новая заметка'),
        leading: FormCloseButton(),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Сохранить',
              onPressed: _handleSave,
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Панель инструментов Quill
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: QuillSimpleToolbarConfig(
                      showClipboardPaste: true,
                      multiRowsDisplay: false,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          afterButtonPressed: () {
                            // Возвращаем фокус в редактор после нажатия кнопки
                            _editorFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Редактор Quill
                Expanded(
                  child: QuillEditor(
                    focusNode: _editorFocusNode,
                    scrollController: _editorScrollController,
                    controller: _quillController,
                    config: QuillEditorConfig(
                      placeholder: 'Начните писать заметку...',
                      padding: const EdgeInsets.all(16),
                      expands: true,
                    ),
                  ),
                ),

                // Закрепленная панель снизу с кнопками
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: SmoothButton(
                            label: 'Отмена',
                            onPressed: state.isSaving
                                ? null
                                : () => context.pop(false),
                            type: SmoothButtonType.outlined,
                            variant: SmoothButtonVariant.normal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SmoothButton(
                            label: isEditMode ? 'Сохранить' : 'Создать',
                            onPressed: state.isSaving ? null : _handleSave,
                            type: SmoothButtonType.filled,
                            variant: SmoothButtonVariant.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

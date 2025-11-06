import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Показать модальное окно для создания/редактирования тега
void showTagModal(
  BuildContext context, {
  TagCardDto? tag,
  VoidCallback? onSuccess,
}) {
  final isEditMode = tag != null;

  WoltModalSheet.show(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    pageListBuilder: (modalContext) {
      final theme = Theme.of(modalContext);
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Builder(
            builder: (context) {
              return Text(
                isEditMode ? 'Редактировать тег' : 'Создать тег',
                style: theme.textTheme.titleMedium,
              );
            },
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(modalContext).pop(),
              );
            },
          ),
          child: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(24),
              child: _TagForm(
                tag: tag,
                onSuccess: () {
                  Navigator.of(modalContext).pop();
                  onSuccess?.call();
                },
                onCancel: () => Navigator.of(modalContext).pop(),
              ),
            ),
          ),
        ),
      ];
    },
  );
}

/// Обёртки для обратной совместимости
void showTagCreateModal(BuildContext context, {VoidCallback? onSuccess}) {
  showTagModal(context, onSuccess: onSuccess);
}

void showTagEditModal(
  BuildContext context,
  TagCardDto tag, {
  VoidCallback? onSuccess,
}) {
  showTagModal(context, tag: tag, onSuccess: onSuccess);
}

/// Универсальная форма создания/редактирования тега
class _TagForm extends ConsumerStatefulWidget {
  final TagCardDto? tag;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _TagForm({this.tag, required this.onSuccess, required this.onCancel});

  @override
  ConsumerState<_TagForm> createState() => _TagFormState();
}

class _TagFormState extends ConsumerState<_TagForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  Color? _selectedColor;
  late TagType _selectedType;
  bool _isLoading = false;

  bool get _isEditMode => widget.tag != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // Режим редактирования - загружаем данные из тега
      _name = widget.tag!.name;
      _selectedType = TagTypeX.fromString(widget.tag!.type);

      // Конвертируем HEX строку в Color если есть
      if (widget.tag!.color != null && widget.tag!.color!.isNotEmpty) {
        try {
          final hexColor = widget.tag!.color!.replaceAll('#', '');
          _selectedColor = Color(int.parse('FF$hexColor', radix: 16));
        } catch (e) {
          _selectedColor = null;
        }
      }
    } else {
      // Режим создания - значения по умолчанию
      _name = '';
      _selectedColor = null;
      _selectedType = TagType.mixed;
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = _selectedColor ?? Colors.blue;
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedColor = pickerColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Выбрать'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Название тега
          TextFormField(
            initialValue: _isEditMode ? _name : null,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Введите название тега',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Название тега не может быть пустым';
              }
              return null;
            },
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),

          // Тип тега
          if (_isEditMode)
            // В режиме редактирования - только для чтения
            TextFormField(
              initialValue: _getTagTypeLabel(_selectedType),
              decoration: primaryInputDecoration(
                context,
                labelText: 'Тип тега',
              ),
              enabled: false,
            )
          else
            // В режиме создания - dropdown
            DropdownButtonFormField<TagType>(
              value: _selectedType,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Тип тега',
              ),
              items: TagType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTagTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          const SizedBox(height: 16),

          // Выбор цвета
          InputDecorator(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Цвет тега',
              hintText: 'Нажмите для выбора цвета',
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showColorPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor ?? Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedColor != null
                            ? '#${_selectedColor!.value.toRadixString(16).substring(2).toUpperCase()}'
                            : 'Не выбран',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : widget.onCancel,
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Сохранить' : 'Создать'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tagDao = await ref.read(tagDaoProvider.future);

      // Конвертируем Color в HEX строку без альфа-канала
      String? colorHex;
      if (_selectedColor != null) {
        colorHex = _selectedColor!.value
            .toRadixString(16)
            .substring(2)
            .toUpperCase();
      }

      if (_isEditMode) {
        // Режим редактирования
        final dto = UpdateTagDto(name: _name.trim(), color: colorHex);

        await tagDao.updateTag(widget.tag!.id, dto);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Тег успешно обновлен')));
          widget.onSuccess();
        }
      } else {
        // Режим создания
        final dto = CreateTagDto(
          name: _name.trim(),
          type: _selectedType.value,
          color: colorHex,
        );

        await tagDao.createTag(dto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Тег "$_name" успешно создан')),
          );
          widget.onSuccess();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Ошибка обновления: $e' : 'Ошибка создания: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Получить человекочитаемое название типа тега
String _getTagTypeLabel(TagType type) {
  switch (type) {
    case TagType.notes:
      return 'Заметки';
    case TagType.password:
      return 'Пароли';
    case TagType.totp:
      return 'TOTP коды';
    case TagType.bankCard:
      return 'Банковские карты';
    case TagType.files:
      return 'Файлы';
    case TagType.mixed:
      return 'Смешанный';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/features/password_manager/icon_manager/features/icon_picker/icon_picker_button.dart';

/// Показать модальное окно для создания категории
void showCategoryCreateModal(BuildContext context, {VoidCallback? onSuccess}) {
  WoltModalSheet.show(
    context: context,
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
                'Создать категорию',
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
              child: _CategoryCreateForm(
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

/// Форма создания категории
class _CategoryCreateForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _CategoryCreateForm({required this.onSuccess, required this.onCancel});

  @override
  ConsumerState<_CategoryCreateForm> createState() =>
      _CategoryCreateFormState();
}

class _CategoryCreateFormState extends ConsumerState<_CategoryCreateForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _description;
  Color? _selectedColor;
  String? _iconId;
  CategoryType _selectedType = CategoryType.mixed;
  bool _isLoading = false;

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
          // Выбор иконки
          Center(
            child: IconPickerButton(
              selectedIconId: _iconId,
              onIconSelected: (id) {
                setState(() {
                  _iconId = id;
                });
              },
              size: 120,
              hintText: 'Выбрать иконку\n(необязательно)',
            ),
          ),
          const SizedBox(height: 24),

          // Название категории
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Введите название категории',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите название';
              }
              return null;
            },
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),

          // Тип категории (dropdown)
          DropdownButtonFormField<CategoryType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип категории',
              border: OutlineInputBorder(),
            ),
            items: CategoryType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getCategoryTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Описание
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Введите описание категории (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _description = value.isEmpty ? null : value;
            },
          ),
          const SizedBox(height: 16),

          // Выбор цвета
          InkWell(
            onTap: _showColorPicker,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Цвет категории',
                hintText: 'Нажмите для выбора цвета',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedColor != null ? 'Цвет выбран' : 'Выберите цвет',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor ?? Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
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
                    : const Text('Создать'),
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
      final categoryDao = await ref.read(categoryDaoProvider.future);

      // Конвертируем Color в HEX строку без альфа-канала
      String? colorHex;
      if (_selectedColor != null) {
        colorHex = _selectedColor!.value
            .toRadixString(16)
            .substring(2)
            .toUpperCase();
      }

      final dto = CreateCategoryDto(
        name: _name.trim(),
        type: _selectedType.value,
        description: _description,
        color: colorHex,
        iconId: _iconId,
      );

      await categoryDao.createCategory(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Категория "$_name" успешно создана')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Показать модальное окно для редактирования категории
void showCategoryEditModal(
  BuildContext context,
  CategoryCardDto category, {
  VoidCallback? onSuccess,
}) {
  WoltModalSheet.show(
    context: context,
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
                'Редактировать категорию',
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
              child: _CategoryEditForm(
                category: category,
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

/// Форма редактирования категории
class _CategoryEditForm extends ConsumerStatefulWidget {
  final CategoryCardDto category;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _CategoryEditForm({
    required this.category,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  ConsumerState<_CategoryEditForm> createState() => _CategoryEditFormState();
}

class _CategoryEditFormState extends ConsumerState<_CategoryEditForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  String? _description;
  Color? _selectedColor;
  String? _iconId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.category.name;
    _description = null; // CategoryCardDto не содержит description
    _iconId = widget.category.iconId;

    // Конвертируем HEX строку в Color если есть
    if (widget.category.color != null && widget.category.color!.isNotEmpty) {
      try {
        final hexColor = widget.category.color!.replaceAll('#', '');
        _selectedColor = Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        _selectedColor = null;
      }
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
          // Выбор иконки
          Center(
            child: IconPickerButton(
              selectedIconId: _iconId,
              onIconSelected: (id) {
                setState(() {
                  _iconId = id;
                });
              },
              size: 120,
              hintText: 'Выбрать иконку\n(необязательно)',
            ),
          ),
          const SizedBox(height: 24),

          // Название категории
          TextFormField(
            initialValue: _name,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Введите название категории',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите название';
              }
              return null;
            },
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),

          // Тип категории (только для отображения, нельзя изменить)
          TextFormField(
            initialValue: _getCategoryTypeLabel(
              CategoryTypeX.fromString(widget.category.type),
            ),
            decoration: const InputDecoration(
              labelText: 'Тип категории',
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Описание
          TextFormField(
            initialValue: _description,
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Введите описание категории (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _description = value.isEmpty ? null : value;
            },
          ),
          const SizedBox(height: 16),

          // Выбор цвета
          InkWell(
            onTap: _showColorPicker,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Цвет категории',
                hintText: 'Нажмите для выбора цвета',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedColor != null ? 'Цвет выбран' : 'Выберите цвет',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor ?? Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
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
                    : const Text('Сохранить'),
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
      final categoryDao = await ref.read(categoryDaoProvider.future);

      // Конвертируем Color в HEX строку без альфа-канала
      String? colorHex;
      if (_selectedColor != null) {
        colorHex = _selectedColor!.value
            .toRadixString(16)
            .substring(2)
            .toUpperCase();
      }

      final dto = UpdateCategoryDto(
        name: _name.trim(),
        description: _description,
        color: colorHex,
        iconId: _iconId,
      );

      await categoryDao.updateCategory(widget.category.id, dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Категория успешно обновлена')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Получить человекочитаемое название типа категории
String _getCategoryTypeLabel(CategoryType type) {
  switch (type) {
    case CategoryType.notes:
      return 'Заметки';
    case CategoryType.password:
      return 'Пароли';
    case CategoryType.totp:
      return 'TOTP коды';
    case CategoryType.bankCard:
      return 'Банковские карты';
    case CategoryType.files:
      return 'Файлы';
    case CategoryType.mixed:
      return 'Смешанная';
  }
}

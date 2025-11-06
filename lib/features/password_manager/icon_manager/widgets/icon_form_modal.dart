import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:image/image.dart' as img;
import '../provider/icon_list_provider.dart';

// Константы
const int _maxFileSizeBytes = 500 * 1024; // 500 KB
const int _targetImageSize = 256; // 256x256 px

/// Обрезать изображение до 256x256
Future<Uint8List> _resizeImage(Uint8List imageData) async {
  final image = img.decodeImage(imageData);
  if (image == null) {
    throw Exception('Не удалось декодировать изображение');
  }

  // Обрезаем изображение до 256x256 с сохранением пропорций
  final resized = img.copyResize(
    image,
    width: _targetImageSize,
    height: _targetImageSize,
    interpolation: img.Interpolation.linear,
  );

  // Кодируем обратно в PNG
  return Uint8List.fromList(img.encodePng(resized));
}

/// Проверить размер файла
bool _checkFileSize(Uint8List data) {
  return data.length <= _maxFileSizeBytes;
}

/// Виджет для предпросмотра иконки
Widget _buildIconPreview(Uint8List data, String type) {
  final isSvg =
      type.toLowerCase() == 'svg' ||
      type.toLowerCase() == 'image/svg+xml' ||
      type.toLowerCase().contains('svg');

  if (isSvg) {
    return SvgPicture.memory(
      data,
      height: 80,
      width: 80,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  } else {
    return Image.memory(
      data,
      height: 80,
      width: 80,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.image, size: 80);
      },
    );
  }
}

/// Показать модальное окно для создания или редактирования иконки
void showIconModal(
  BuildContext context,
  WidgetRef ref, {
  IconCardDto? icon, // Если передано - режим редактирования, иначе - создание
  VoidCallback? onSuccess,
}) {
  final formKey = GlobalKey<FormState>();
  final isEditMode = icon != null;
  String name = icon?.name ?? '';
  String type = icon?.type ?? '';
  Uint8List? iconData;
  Uint8List? currentIconData;
  String? fileName;
  bool isLoading = false;

  // Загружаем текущие данные иконки для режима редактирования
  Future<Uint8List?> _loadIconData() async {
    if (!isEditMode) return null;
    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      final data = await iconDao.getIconData(icon.id);
      logDebug(
        'Loaded icon data for editing, ID: ${icon.id}, Size: ${data?.length ?? 0} bytes',
      );
      return data;
    } catch (e) {
      debugPrint('Ошибка загрузки данных иконки: $e');
      return null;
    }
  }

  // Обработка выбора файла
  Future<void> _pickFile(StateSetter setState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      if (file.bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось загрузить файл'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        Uint8List processedData = file.bytes!;
        final fileExtension = file.extension?.toLowerCase() ?? '';

        // Проверяем размер файла
        if (!_checkFileSize(processedData)) {
          throw Exception(
            'Размер файла превышает 500 КБ (${(processedData.length / 1024).toStringAsFixed(1)} КБ)',
          );
        }

        // Для PNG обрезаем до 256x256
        if (fileExtension == 'png') {
          processedData = await _resizeImage(processedData);

          // Проверяем размер после обрезки
          if (!_checkFileSize(processedData)) {
            throw Exception('Размер файла после обработки превышает 500 КБ');
          }
        }

        setState(() {
          iconData = processedData;
          fileName = file.name;
          type = fileExtension;
        });
      } catch (e) {
        if (context.mounted) {
          Toaster.error(title: 'Ошибка обработки файла', description: '$e');
        }
      }
    }
  }

  // Сохранение иконки
  Future<void> _saveIcon(BuildContext modalContext) async {
    if (!formKey.currentState!.validate()) return;

    if (iconData == null && !isEditMode) {
      Toaster.error(title: 'Ошибка', description: 'Пожалуйста, выберите файл');
      return;
    }

    try {
      // Проверяем, что тип заполнен
      if (type.trim().isEmpty) {
        throw Exception('Тип иконки не определён. Проверьте расширение файла.');
      }

      final iconDao = await ref.read(iconDaoProvider.future);

      if (isEditMode) {
        // Обновление
        final dto = UpdateIconDto(
          name: name.trim() != icon.name ? name.trim() : null,
          type: type.trim() != icon.type ? type.trim() : null,
          data: iconData,
        );
        await iconDao.updateIcon(icon.id, dto);
      } else {
        // Создание
        final dto = CreateIconDto(
          name: name.trim(),
          type: type.trim(),
          data: iconData!,
        );
        await iconDao.createIcon(dto);
      }

      // Обновляем список иконок
      await ref.read(iconListProvider.notifier).refresh();

      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
        Toaster.success(
          title: isEditMode
              ? 'Иконка успешно обновлена'
              : 'Иконка успешно создана',
        );

        onSuccess?.call();
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка ${isEditMode ? 'обновления' : 'создания'} иконки: $e');
      debugPrint('StackTrace: $stackTrace');
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка ${isEditMode ? 'обновления' : 'создания'}',
          description: '${e.toString()}',
        );
      }
    }
  }

  WoltModalSheet.show(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    useSafeArea: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            isEditMode ? 'Редактировать иконку' : 'Создать иконку',
            style: Theme.of(modalContext).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalContext).pop(),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              // Для режима редактирования показываем FutureBuilder
              if (isEditMode) {
                return FutureBuilder<Uint8List?>(
                  future: _loadIconData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    currentIconData = snapshot.data;

                    return _buildForm(
                      context,
                      setState,
                      modalContext,
                      formKey,
                      name,
                      (value) => name = value,
                      iconData,
                      currentIconData,
                      fileName,
                      type,
                      isLoading,
                      (loading) => setState(() => isLoading = loading),
                      () => _pickFile(setState),
                      () async {
                        setState(() => isLoading = true);
                        await _saveIcon(modalContext);
                        setState(() => isLoading = false);
                      },
                      isEditMode,
                    );
                  },
                );
              }

              // Для режима создания сразу показываем форму
              return _buildForm(
                context,
                setState,
                modalContext,
                formKey,
                name,
                (value) => name = value,
                iconData,
                currentIconData,
                fileName,
                type,
                isLoading,
                (loading) => setState(() => isLoading = loading),
                () => _pickFile(setState),
                () async {
                  setState(() => isLoading = true);
                  await _saveIcon(modalContext);
                  setState(() => isLoading = false);
                },
                isEditMode,
              );
            },
          ),
        ),
      ];
    },
  );
}

/// Построение формы
Widget _buildForm(
  BuildContext context,
  StateSetter setState,
  BuildContext modalContext,
  GlobalKey<FormState> formKey,
  String name,
  Function(String) onNameChanged,
  Uint8List? iconData,
  Uint8List? currentIconData,
  String? fileName,
  String type,
  bool isLoading,
  Function(bool) setLoading,
  VoidCallback onPickFile,
  VoidCallback onSave,
  bool isEditMode,
) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Текущая иконка (только для режима редактирования)
          if (isEditMode) ...[
            if (currentIconData != null && currentIconData.isNotEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: _buildIconPreview(currentIconData, type)),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Название иконки
          TextFormField(
            initialValue: name,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Введите название иконки',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите название';
              }
              return null;
            },
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),

          // Выбор файла
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(
              fileName ??
                  (isEditMode ? 'Изменить файл (опционально)' : 'Выбрать файл'),
            ),
          ),

          if (fileName != null) ...[
            const SizedBox(height: 8),
            Text(
              '${isEditMode ? 'Новый файл' : 'Выбран'}: $fileName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Поддерживаемые форматы: SVG, PNG (макс. 500 КБ)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Поддерживаемые форматы: SVG, PNG (макс. 500 КБ)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'PNG будет автоматически обрезан до 256x256 px',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (iconData != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: _buildIconPreview(iconData, type)),
            ),
          ],

          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLoading ? null : onSave,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditMode ? 'Сохранить' : 'Создать'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Показать модальное окно для создания иконки
void showIconCreateModal(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) {
  showIconModal(context, ref, onSuccess: onSuccess);
}

/// Показать модальное окно для редактирования иконки
void showIconEditModal(
  BuildContext context,
  WidgetRef ref,
  IconCardDto icon, {
  VoidCallback? onSuccess,
}) {
  showIconModal(context, ref, icon: icon, onSuccess: onSuccess);
}

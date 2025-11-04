import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import '../provider/icon_list_provider.dart';

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

/// Показать модальное окно для создания иконки
void showIconCreateModal(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) {
  final formKey = GlobalKey<FormState>();
  String name = '';
  String type = '';
  Uint8List? iconData;
  String? fileName;
  bool isLoading = false;

  WoltModalSheet.show(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Создать иконку',
            style: Theme.of(modalContext).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalContext).pop(),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Название иконки
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Введите название иконки',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите название';
                        }
                        return null;
                      },
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),

                    // Выбор файла
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'svg',
                            'png',
                            'jpg',
                            'jpeg',
                            'gif',
                            'webp',
                          ],
                          withData: true,
                        );

                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          setState(() {
                            iconData = file.bytes;
                            fileName = file.name;
                            // Автоматически определяем тип из расширения
                            if (file.extension != null &&
                                file.extension!.isNotEmpty) {
                              type = file.extension!;
                            } else {
                              // Если расширение не определено, пробуем извлечь из имени
                              final nameParts = file.name.split('.');
                              if (nameParts.length > 1) {
                                type = nameParts.last;
                              }
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(fileName ?? 'Выбрать файл'),
                    ),

                    if (fileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Выбран: $fileName',
                        style: Theme.of(context).textTheme.bodySmall,
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
                        child: Center(
                          child: _buildIconPreview(iconData!, type),
                        ),
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
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    if (iconData == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Пожалуйста, выберите файл',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      // Проверяем, что тип заполнен
                                      if (type.trim().isEmpty) {
                                        throw Exception(
                                          'Тип иконки не определён. Проверьте расширение файла.',
                                        );
                                      }

                                      final iconDao = await ref.read(
                                        iconDaoProvider.future,
                                      );
                                      final dto = CreateIconDto(
                                        name: name.trim(),
                                        type: type.trim(),
                                        data: iconData!,
                                      );
                                      await iconDao.createIcon(dto);

                                      // Обновляем список иконок
                                      await ref
                                          .read(iconListProvider.notifier)
                                          .refresh();

                                      if (modalContext.mounted) {
                                        Navigator.of(modalContext).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Иконка успешно создана',
                                            ),
                                          ),
                                        );
                                        onSuccess?.call();
                                      }
                                    } catch (e, stackTrace) {
                                      setState(() => isLoading = false);
                                      // Логируем полную ошибку для отладки
                                      debugPrint('Ошибка создания иконки: $e');
                                      debugPrint('StackTrace: $stackTrace');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Ошибка создания: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 5,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Создать'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    },
  );
}

/// Показать модальное окно для редактирования иконки
void showIconEditModal(
  BuildContext context,
  WidgetRef ref,
  IconCardDto icon, {
  VoidCallback? onSuccess,
}) {
  final formKey = GlobalKey<FormState>();
  String name = icon.name;
  String type = icon.type;
  Uint8List? iconData;
  String? fileName;
  bool isLoading = false;

  WoltModalSheet.show(
    context: context,
    barrierDismissible: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Редактировать иконку',
            style: Theme.of(modalContext).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalContext).pop(),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Текущая иконка
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _buildIconPreview(
                          Uint8List.fromList(icon.data),
                          icon.type,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Название иконки
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Введите название иконки',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите название';
                        }
                        return null;
                      },
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),

                    // Выбор нового файла (опционально)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'svg',
                            'png',
                            'jpg',
                            'jpeg',
                            'gif',
                            'webp',
                          ],
                          withData: true,
                        );

                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          setState(() {
                            iconData = file.bytes;
                            fileName = file.name;
                            // Автоматически определяем тип из расширения
                            if (file.extension != null &&
                                file.extension!.isNotEmpty) {
                              type = file.extension!;
                            } else {
                              // Если расширение не определено, пробуем извлечь из имени
                              final nameParts = file.name.split('.');
                              if (nameParts.length > 1) {
                                type = nameParts.last;
                              }
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(fileName ?? 'Изменить файл (опционально)'),
                    ),

                    if (fileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Новый файл: $fileName',
                        style: Theme.of(context).textTheme.bodySmall,
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
                        child: Center(
                          child: _buildIconPreview(iconData!, type),
                        ),
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
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setState(() => isLoading = true);

                                    try {
                                      // Проверяем, что тип заполнен
                                      if (type.trim().isEmpty) {
                                        throw Exception(
                                          'Тип иконки не определён. Проверьте расширение файла.',
                                        );
                                      }

                                      final iconDao = await ref.read(
                                        iconDaoProvider.future,
                                      );
                                      final dto = UpdateIconDto(
                                        name: name.trim() != icon.name
                                            ? name.trim()
                                            : null,
                                        type: type.trim() != icon.type
                                            ? type.trim()
                                            : null,
                                        data: iconData,
                                      );
                                      await iconDao.updateIcon(icon.id, dto);

                                      // Обновляем список иконок
                                      await ref
                                          .read(iconListProvider.notifier)
                                          .refresh();

                                      if (modalContext.mounted) {
                                        Navigator.of(modalContext).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Иконка успешно обновлена',
                                            ),
                                          ),
                                        );
                                        onSuccess?.call();
                                      }
                                    } catch (e, stackTrace) {
                                      setState(() => isLoading = false);
                                      // Логируем полную ошибку для отладки
                                      debugPrint(
                                        'Ошибка обновления иконки: $e',
                                      );
                                      debugPrint('StackTrace: $stackTrace');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Ошибка обновления: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 5,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Сохранить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    },
  );
}

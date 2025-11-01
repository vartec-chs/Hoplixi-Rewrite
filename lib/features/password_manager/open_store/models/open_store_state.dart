import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_store_state.freezed.dart';

/// Состояние экрана открытия хранилища
@freezed
sealed class OpenStoreState with _$OpenStoreState {
  const factory OpenStoreState({
    /// Список доступных хранилищ
    @Default([]) List<StorageInfo> storages,

    /// Выбранное хранилище
    StorageInfo? selectedStorage,

    /// Пароль для открытия
    @Default('') String password,

    /// Флаг процесса открытия
    @Default(false) bool isOpening,

    /// Флаг загрузки списка хранилищ
    @Default(false) bool isLoading,

    /// Ошибка при вводе пароля
    String? passwordError,

    /// Общая ошибка
    String? error,
  }) = _OpenStoreState;
}

/// Информация о хранилище
@freezed
sealed class StorageInfo with _$StorageInfo {
  const factory StorageInfo({
    /// Имя хранилища
    required String name,

    /// Полный путь к файлу базы данных
    required String path,

    /// Дата последнего изменения
    required DateTime modifiedAt,

    /// Описание (опционально)
    String? description,

    /// Размер файла в байтах
    int? size,

    /// Из истории или из папки
    @Default(false) bool fromHistory,

    /// Последнее время открытия (для истории)
    DateTime? lastOpenedAt,
  }) = _StorageInfo;

  const StorageInfo._();

  /// Форматированный размер файла
  String get formattedSize {
    if (size == null) return 'Неизвестно';
    final kb = size! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  /// Форматированная дата изменения
  String get formattedModifiedDate {
    final now = DateTime.now();
    final difference = now.difference(modifiedAt);

    if (difference.inMinutes < 1) return 'Только что';
    if (difference.inHours < 1) return '${difference.inMinutes} мин назад';
    if (difference.inDays < 1) return '${difference.inHours} ч назад';
    if (difference.inDays < 7) return '${difference.inDays} дн назад';

    return '${modifiedAt.day}.${modifiedAt.month}.${modifiedAt.year}';
  }
}

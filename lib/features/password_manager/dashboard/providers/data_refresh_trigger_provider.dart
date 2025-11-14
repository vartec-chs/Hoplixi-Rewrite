import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/data_refresh_state.dart';

/// Провайдер для триггера обновления данных
/// Используется для оповещения о том, что данные изменились и нужно перезапросить
final dataRefreshTriggerProvider =
    NotifierProvider<DataRefreshTriggerNotifier, DataRefreshState>(
      () => DataRefreshTriggerNotifier(),
    );

class DataRefreshTriggerNotifier extends Notifier<DataRefreshState> {
  @override
  DataRefreshState build() {
    logDebug('DataRefreshTriggerNotifier: Инициализация');
    return DataRefreshState(
      type: DataRefreshType.add,
      timestamp: DateTime.now(),
    );
  }

  void _emitRefreshState({
    required DataRefreshType type,
    EntityType? entityType,
    String? entityId,
    String? reason,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    final entityTag = entityType != null ? ' для $entityType' : '';
    logDebug(
      'DataRefreshTriggerNotifier: ${reason ?? 'Триггер обновления'}$entityTag в $now',
      data: data,
    );
    state = DataRefreshState(
      type: type,
      timestamp: now,
      entityId: entityId ?? entityType?.toString(),
      entityType: entityType,
    );
  }

  /// Триггерит обновление данных
  /// Вызывайте этот метод когда данные изменились и нужно обновить UI
  // void triggerRefresh() {
  //   final now = DateTime.now();
  //   logDebug('DataRefreshTriggerNotifier: Триггер обновления данных в $now');
  //   state = DataRefreshState(type: DataRefreshType.update, timestamp: now);
  // }

  /// Триггерит обновление с указанным типом сущности
  /// Полезно для избирательного обновления только определенных данных
  void triggerRefreshForEntity(
    EntityType entityType, {
    DataRefreshType type = DataRefreshType.update,
    String? entityId,
  }) {
    _emitRefreshState(type: type, entityType: entityType, entityId: entityId);
  }

  /// Триггерит добавление сущности
  void triggerEntityAdd(EntityType entityType, {String? entityId}) {
    triggerRefreshForEntity(
      entityType,
      type: DataRefreshType.add,
      entityId: entityId,
    );
  }

  /// Триггерит обновление сущности
  void triggerEntityUpdate(EntityType entityType, {String? entityId}) {
    triggerRefreshForEntity(
      entityType,
      type: DataRefreshType.update,
      entityId: entityId,
    );
  }

  /// Триггерит удаление сущности
  void triggerEntityDelete(EntityType entityType, {String? entityId}) {
    triggerRefreshForEntity(
      entityType,
      type: DataRefreshType.delete,
      entityId: entityId,
    );
  }

  /// Триггерит обновление с дополнительной информацией
  void triggerRefreshWithInfo(
    String reason, {
    EntityType? entityType,
    DataRefreshType type = DataRefreshType.update,
    String? entityId,
    Map<String, dynamic>? data,
  }) {
    _emitRefreshState(
      type: type,
      entityType: entityType,
      entityId: entityId,
      reason: reason,
      data: data,
    );
  }

  /// Триггерит универсальное обновление
  void triggerRefreshAll({String? reason}) {
    _emitRefreshState(
      type: DataRefreshType.update,
      reason: reason ?? 'Обновление всех данных',
    );
  }
}

/// Провайдер для отслеживания последнего обновления
/// Удобен для отображения времени последнего обновления в UI
final lastDataRefreshProvider = Provider<DataRefreshState>((ref) {
  return ref.watch(dataRefreshTriggerProvider);
});

/// Провайдер для проверки необходимости обновления
/// Возвращает true если данные устарели (старше указанного времени)
final isDataStaleProvider = Provider.family<bool, Duration>((ref, maxAge) {
  final lastRefresh = ref.watch(dataRefreshTriggerProvider);
  final now = DateTime.now();
  final isStale = now.difference(lastRefresh.timestamp) > maxAge;
  return isStale;
});

/// Удобные методы для работы с обновлениями данных
class DataRefreshHelper {
  /// Обновляет данные паролей
  static void refreshPasswords(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.password);
  }

  /// Обновляет данные заметок
  static void refreshNotes(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.note);
  }

  /// Обновляет данные OTP
  static void refreshOtp(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.otp);
  }

  /// Обновляет данные банковских карт
  static void refreshBankCards(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.bankCard);
  }

  /// Обновляет данные файлов
  static void refreshFiles(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.file);
  }

  /// Обновляет все данные
  static void refreshAll(WidgetRef ref) {
    ref.read(dataRefreshTriggerProvider.notifier).triggerRefreshAll();
  }

  /// Обновляет данные после создания элемента
  static void refreshAfterCreate(
    WidgetRef ref,
    EntityType entityType,
    String id,
  ) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityAdd(entityType, entityId: id);
  }

  /// Обновляет данные после обновления элемента
  static void refreshAfterUpdate(
    WidgetRef ref,
    EntityType entityType,
    String id,
  ) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(entityType, entityId: id);
  }

  /// Обновляет данные после удаления элемента
  static void refreshAfterDelete(
    WidgetRef ref,
    EntityType entityType,
    String id,
  ) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityDelete(entityType, entityId: id);
  }

  /// Обновляет данные с кастомной причиной
  static void refreshWithReason(
    WidgetRef ref,
    String reason, {
    EntityType? entityType,
    DataRefreshType type = DataRefreshType.update,
    String? entityId,
    Map<String, dynamic>? data,
  }) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshWithInfo(
          reason,
          entityType: entityType,
          type: type,
          entityId: entityId,
          data: data,
        );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';

/// Провайдер для триггера обновления данных
/// Используется для оповещения о том, что данные изменились и нужно перезапросить
final dataRefreshTriggerProvider =
    NotifierProvider<DataRefreshTriggerNotifier, DateTime>(
      () => DataRefreshTriggerNotifier(),
    );

class DataRefreshTriggerNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    logDebug('DataRefreshTriggerNotifier: Инициализация');
    return DateTime.now();
  }

  /// Триггерит обновление данных
  /// Вызывайте этот метод когда данные изменились и нужно обновить UI
  void triggerRefresh() {
    final now = DateTime.now();
    logDebug('DataRefreshTriggerNotifier: Триггер обновления данных в $now');
    state = now;
  }

  /// Триггерит обновление с указанным типом сущности
  /// Полезно для избирательного обновления только определенных данных
  void triggerRefreshForEntity(EntityType entityType) {
    final now = DateTime.now();
    logDebug(
      'DataRefreshTriggerNotifier: Триггер обновления для $entityType в $now',
    );
    state = now;
  }

  /// Триггерит обновление с дополнительной информацией
  void triggerRefreshWithInfo(String reason, {Map<String, dynamic>? data}) {
    final now = DateTime.now();
    logDebug(
      'DataRefreshTriggerNotifier: Триггер обновления по причине "$reason" в $now',
      data: data,
    );
    state = now;
  }
}

/// Провайдер для отслеживания последнего обновления
/// Удобен для отображения времени последнего обновления в UI
final lastDataRefreshProvider = Provider<DateTime>((ref) {
  return ref.watch(dataRefreshTriggerProvider);
});

/// Провайдер для проверки необходимости обновления
/// Возвращает true если данные устарели (старше указанного времени)
final isDataStaleProvider = Provider.family<bool, Duration>((ref, maxAge) {
  final lastRefresh = ref.watch(dataRefreshTriggerProvider);
  final now = DateTime.now();
  final isStale = now.difference(lastRefresh) > maxAge;
  return isStale;
});

/// Удобные методы для работы с обновлениями данных
class DataRefreshHelper {
  /// Обновляет данные паролей
  static void refreshPasswords(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshForEntity(EntityType.password);
  }

  /// Обновляет данные заметок
  static void refreshNotes(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshForEntity(EntityType.note);
  }

  /// Обновляет данные OTP
  static void refreshOtp(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshForEntity(EntityType.otp);
  }

  /// Обновляет данные банковских карт
  static void refreshBankCards(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshForEntity(EntityType.bankCard);
  }

  /// Обновляет данные файлов
  static void refreshFiles(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshForEntity(EntityType.file);
  }

  /// Обновляет все данные
  static void refreshAll(WidgetRef ref) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshWithInfo('Обновление всех данных');
  }

  /// Обновляет данные после создания элемента
  static void refreshAfterCreate(WidgetRef ref, String entityType) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshWithInfo(
          'Создан новый элемент',
          data: {'entityType': entityType, 'action': 'create'},
        );
  }

  /// Обновляет данные после обновления элемента
  static void refreshAfterUpdate(WidgetRef ref, String entityType, String id) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshWithInfo(
          'Обновлен элемент',
          data: {'entityType': entityType, 'action': 'update', 'id': id},
        );
  }

  /// Обновляет данные после удаления элемента
  static void refreshAfterDelete(WidgetRef ref, String entityType, String id) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerRefreshWithInfo(
          'Удален элемент',
          data: {'entityType': entityType, 'action': 'delete', 'id': id},
        );
  }
}

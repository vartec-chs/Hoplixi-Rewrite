import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type_state.dart';

/// Провайдер для управления текущим типом сущности
final entityTypeProvider =
    NotifierProvider<EntityTypeNotifier, EntityTypeState>(
      EntityTypeNotifier.new,
    );

class EntityTypeNotifier extends Notifier<EntityTypeState> {
  @override
  EntityTypeState build() {
    // Инициализируем с паролями по умолчанию
    return EntityTypeState(
      currentType: EntityType.password,
      availableTypes: {for (final type in EntityType.values) type: true},
    );
  }

  /// Переключить на тип сущности
  void selectType(EntityType type) {
    state = state.copyWith(currentType: type);
  }

  /// Переключить доступность типа сущности
  void toggleTypeAvailability(EntityType type) {
    final updated = Map<EntityType, bool>.from(state.availableTypes);
    updated[type] = !(updated[type] ?? true);
    state = state.copyWith(availableTypes: updated);
  }

  /// Установить доступность типа сущности
  void setTypeAvailability(EntityType type, bool isAvailable) {
    final updated = Map<EntityType, bool>.from(state.availableTypes);
    updated[type] = isAvailable;
    state = state.copyWith(availableTypes: updated);
  }

  /// Установить доступность нескольких типов сущностей
  void setTypesAvailability(Map<EntityType, bool> availableTypes) {
    state = state.copyWith(availableTypes: availableTypes);
  }

  /// Получить только доступные типы
  List<EntityType> getAvailableTypes() {
    return state.availableTypes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Проверить доступен ли тип
  bool isTypeAvailable(EntityType type) {
    return state.availableTypes[type] ?? false;
  }

  /// Сбросить на значения по умолчанию (все типы доступны, пароли выбраны)
  void reset() {
    state = EntityTypeState(
      currentType: EntityType.password,
      availableTypes: {for (final type in EntityType.values) type: true},
    );
  }
}

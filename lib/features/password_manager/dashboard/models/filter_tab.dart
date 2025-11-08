import 'package:flutter/material.dart';
import 'entity_type.dart';

enum FilterTab {
  all('Все', Icons.list),
  favorites('Избранные', Icons.star),
  frequent('Часто используемые', Icons.access_time),
  archived('Архив', Icons.archive),
  delete('Удаленные', Icons.delete);

  final String label;
  final IconData icon;

  const FilterTab(this.label, this.icon);

  /// Получить доступные вкладки для типа сущности
  static List<FilterTab> getAvailableTabsForEntity(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.note:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.otp:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.bankCard:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.file:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
    }
  }
}

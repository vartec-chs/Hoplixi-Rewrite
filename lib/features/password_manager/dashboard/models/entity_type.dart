import 'package:flutter/material.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/routing/paths.dart';

enum EntityType {
  password('password', 'Пароли', Icons.lock),
  note('note', 'Заметки', Icons.note),
  bankCard('bank_card', 'Банковские карты', Icons.credit_card),
  file('file', 'Файлы', Icons.attach_file),
  otp('otp', 'OTP/2FA', Icons.security);

  const EntityType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  /// Получить тип по идентификатору
  static EntityType? fromId(String id) {
    try {
      return EntityType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      logError('Неизвестный тип сущности', error: e, data: {'id': id});
      return null;
    }
  }

  /// Получить тип по индексу
  static EntityType? fromIndex(int index) {
    try {
      return EntityType.values[index];
    } catch (e) {
      logError(
        'Неизвестный индекс типа сущности',
        error: e,
        data: {'index': index},
      );
      return null;
    }
  }

  @override
  String toString() => 'EntityType(id: $id, label: $label, icon: $icon)';
}

// =============================================================================
// EntityType Routing Extension
// =============================================================================

/// Extension для работы с путями навигации для каждого типа сущности
extension EntityTypeRouting on EntityType {
  /// Путь для создания новой сущности
  String get createPath {
    switch (this) {
      case EntityType.password:
        return AppRoutesPaths.dashboardPasswordCreate;
      case EntityType.note:
        return AppRoutesPaths.dashboardNoteCreate;
      case EntityType.bankCard:
        return AppRoutesPaths.dashboardBankCardCreate;
      case EntityType.file:
        return AppRoutesPaths.dashboardFileCreate;
      case EntityType.otp:
        return AppRoutesPaths.dashboardOtpCreate;
    }
  }

  /// Путь для редактирования сущности с указанным ID
  String editPath(String id) {
    switch (this) {
      case EntityType.password:
        return AppRoutesPaths.dashboardPasswordEditWithId(id);
      case EntityType.note:
        return AppRoutesPaths.dashboardNoteEditWithId(id);
      case EntityType.bankCard:
        return AppRoutesPaths.dashboardBankCardEditWithId(id);
      case EntityType.file:
        return AppRoutesPaths.dashboardFileEditWithId(id);
      case EntityType.otp:
        return AppRoutesPaths.dashboardOtpEditWithId(id);
    }
  }

  /// Паттерн пути для определения form route (содержит /<entity>/)
  String get formRoutePattern {
    switch (this) {
      case EntityType.password:
        return '/password/';
      case EntityType.note:
        return '/note/';
      case EntityType.bankCard:
        return '/bank-card/';
      case EntityType.file:
        return '/file/';
      case EntityType.otp:
        return '/otp/';
    }
  }

  /// Проверить, является ли путь form route для этого типа
  bool isFormRoute(String location) {
    return location.contains(formRoutePattern);
  }

  /// Проверить, является ли путь form route для любого типа сущности
  static bool isAnyFormRoute(String location) {
    return EntityType.values.any((type) => type.isFormRoute(location));
  }

  /// Получить тип сущности по пути (если путь является form route)
  static EntityType? fromFormRoute(String location) {
    for (final type in EntityType.values) {
      if (type.isFormRoute(location)) {
        return type;
      }
    }
    return null;
  }

  /// Проверить, должен ли путь открывать sidebar
  ///
  /// Sidebar открывается для:
  /// - Любых форм создания/редактирования (через [isAnyFormRoute])
  /// - Других путей, добавленных в [_sidebarRoutes]
  ///
  /// Для добавления нового пути, который должен открывать sidebar,
  /// добавьте его в список [_sidebarRoutes]
  static bool shouldOpenSidebar(String location) {
    // Проверяем формы
    if (isAnyFormRoute(location)) {
      return true;
    }

    // Проверяем другие пути из списка
    return _sidebarRoutes.any((route) => location.contains(route));
  }

  /// Список дополнительных путей, которые должны открывать sidebar
  ///
  /// Добавьте сюда любые пути, которые должны открывать боковую панель.
  /// Используется проверка через [String.contains], поэтому можно
  /// указывать как полные пути, так и их части.
  ///
  /// Пример:
  /// ```dart
  /// static const List<String> _sidebarRoutes = [
  ///   '/dashboard/detail/',
  ///   '/dashboard/preview/',
  /// ];
  /// ```
  static const List<String> _sidebarRoutes = [
    // Добавьте здесь пути, которые должны открывать sidebar
    // Например: '/dashboard/detail/', '/dashboard/preview/'
    AppRoutesPaths.dashboardMigrateOtp,
    AppRoutesPaths.dashboardMigratePasswords,
  ];
}

import 'pref_category.dart';

/// Унифицированный типизированный ключ для хранения настроек
///
/// Объединяет функциональность PrefKey и SecureKey.
/// Флаг [isProtected] определяет, использовать ли FlutterSecureStorage
/// (для защищённых данных) или SharedPreferences (для обычных настроек).
/// Флаг [biometricProtect] требует подтверждения биометрией при изменении
/// (работает только если biometric_enabled включён в настройках).
class AppKey<T> {
  /// Строковый ключ для хранения значения
  final String key;

  /// Использовать ли защищённое хранилище (FlutterSecureStorage)
  /// Если false - используется SharedPreferences
  final bool isProtected;

  /// Требовать ли подтверждение биометрией при изменении значения
  /// Работает только если biometric_enabled включён в настройках приложения
  final bool biometricProtect;

  /// Скрыть ли эту настройку в UI
  final bool isHiddenUI;

  /// Можно ли редактировать эту настройку в UI
  final bool editable;

  /// Категория настройки для группировки в UI
  final PrefCategory category;

  const AppKey(
    this.key, {
    this.isProtected = false,
    this.biometricProtect = false,
    this.isHiddenUI = false,
    this.editable = true,
    this.category = PrefCategory.general,
  });

  @override
  String toString() => key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppKey && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

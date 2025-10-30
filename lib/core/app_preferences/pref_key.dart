import 'pref_category.dart';

/// Типизированный ключ для SharedPreferences
class PrefKey<T> {
  /// Строковый ключ для хранения значения
  final String key;

  /// Скрыть ли эту настройку в UI
  final bool isHiddenUI;

  /// Можно ли редактировать эту настройку в UI
  final bool editable;

  /// Категория настройки для группировки в UI
  final PrefCategory category;

  const PrefKey(
    this.key, {
    this.isHiddenUI = false,
    this.editable = true,
    this.category = PrefCategory.general,
  });

  @override
  String toString() => key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefKey && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

import 'pref_category.dart';

enum SettingsViewType { toggle, text, number, dropdown, slider }

class SettingsKey<T> {
  final String key;
  final T defaultValue;
  final PrefCategory category;
  final String? group;
  final bool isProtected;
  final bool useBiometricProtect;
  final String label;
  final String? description;
  final SettingsViewType viewType;
  final List<T>? options;

  const SettingsKey({
    required this.key,
    required this.defaultValue,
    required this.label,
    this.category = PrefCategory.general,
    this.group,
    this.isProtected = false,
    this.useBiometricProtect = false,
    this.description,
    this.viewType = SettingsViewType.text,
    this.options,
  });
}

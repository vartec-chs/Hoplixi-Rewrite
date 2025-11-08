import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import '../models/filter_tab.dart';

/// Провайдер для управления текущей выбранной вкладкой фильтра
final filterTabProvider = NotifierProvider<FilterTabNotifier, FilterTab>(
  FilterTabNotifier.new,
);

class FilterTabNotifier extends Notifier<FilterTab> {
  static const String _logTag = 'FilterTabNotifier';

  @override
  FilterTab build() {
    logDebug('Инициализация провайдера вкладок фильтра', tag: _logTag);
    return FilterTab.all; // По умолчанию показываем все элементы
  }

  /// Изменить активную вкладку
  void changeTab(FilterTab tab) {
    if (state == tab) return;

    logDebug(
      'Изменение вкладки фильтра',
      tag: _logTag,
      data: {'from': state.label, 'to': tab.label},
    );

    state = tab;
  }

  /// Сбросить на вкладку "Все"
  void reset() {
    logDebug('Сброс вкладки фильтра на "Все"', tag: _logTag);
    state = FilterTab.all;
  }
}

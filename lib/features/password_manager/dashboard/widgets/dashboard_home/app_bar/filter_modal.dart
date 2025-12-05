import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

// Модели и провайдеры
import '../../../models/entity_type.dart';
import '../../../providers/entity_type_provider.dart';
import '../../../providers/filter_providers/base_filter_provider.dart';
import '../../../providers/filter_providers/password_filter_provider.dart';
import '../../../providers/filter_providers/notes_filter_provider.dart';
import '../../../providers/filter_providers/otp_filter_provider.dart';
import '../../../providers/filter_providers/bank_cards_filter_provider.dart';
import '../../../providers/filter_providers/files_filter_provider.dart';

// Секции фильтров
import '../filter_sections/filter_sections.dart';

/// Типобезопасное хранилище начальных значений фильтров
class _InitialFilterValues {
  final BaseFilter baseFilter;
  final PasswordsFilter? passwordsFilter;
  final NotesFilter? notesFilter;
  final OtpsFilter? otpsFilter;
  final BankCardsFilter? bankCardsFilter;
  final FilesFilter? filesFilter;

  _InitialFilterValues({
    required this.baseFilter,
    this.passwordsFilter,
    this.notesFilter,
    this.otpsFilter,
    this.bankCardsFilter,
    this.filesFilter,
  });
}

/// Модальное окно фильтра на базе WoltModalSheet
/// Адаптируется под выбранный тип сущности
class FilterModal {
  FilterModal._();

  /// Показать модальное окно фильтра
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onFilterApplied,
  }) async {
    logDebug('FilterModal: Открытие модального окна фильтра');

    await WoltModalSheet.show<void>(
      context: context,

      pageListBuilder: (modalSheetContext) {
        return [_buildMainFilterPage(modalSheetContext, onFilterApplied)];
      },
      onModalDismissedWithBarrierTap: () {
        logDebug('FilterModal: Закрытие по тапу на барьер');
        Navigator.of(context).pop();
      },
    );
  }

  /// Построить главную страницу фильтра
  static WoltModalSheetPage _buildMainFilterPage(
    BuildContext context,
    VoidCallback? onFilterApplied,
  ) {
    return WoltModalSheetPage(
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: true,
      topBarTitle: Consumer(
        builder: (context, ref, _) {
          final entityType = ref.watch(entityTypeProvider).currentType;
          return Text(
            'Фильтры: ${entityType.label}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          );
        },
      ),
      trailingNavBarWidget: const ModalSheetCloseButton(),

      child: _FilterModalContent(onFilterApplied: onFilterApplied),
    );
  }
}

/// Основное содержимое модального окна фильтра
class _FilterModalContent extends ConsumerStatefulWidget {
  const _FilterModalContent({this.onFilterApplied});

  final VoidCallback? onFilterApplied;

  @override
  ConsumerState<_FilterModalContent> createState() =>
      _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<_FilterModalContent> {
  // Состояние для выбранных категорий и тегов
  List<String> _selectedCategoryIds = [];
  List<String> _selectedCategoryNames = [];
  List<String> _selectedTagIds = [];
  List<String> _selectedTagNames = [];

  // Типобезопасное хранение начальных значений для отката
  _InitialFilterValues? _initialValues;

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
    logDebug('FilterModal: Инициализация содержимого фильтра');
  }

  void _loadInitialValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _saveInitialValues();
      _loadSelectedCategoriesAndTags();
    });
  }

  void _saveInitialValues() {
    final entityType = ref.read(entityTypeProvider).currentType;
    final baseFilter = ref.read(baseFilterProvider);

    // Сохраняем специфичные для типа значения
    switch (entityType) {
      case EntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          passwordsFilter: passwordFilter,
        );
        break;

      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          notesFilter: notesFilter,
        );
        break;

      case EntityType.otp:
        final otpFilter = ref.read(otpsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          otpsFilter: otpFilter,
        );
        break;

      case EntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          bankCardsFilter: bankCardsFilter,
        );
        break;

      case EntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          filesFilter: filesFilter,
        );
        break;
    }

    logDebug(
      'FilterModal: Сохранены начальные значения',
      data: {
        'entityType': entityType.id,
        'hasBaseFilter': _initialValues != null,
      },
    );
  }

  void _loadSelectedCategoriesAndTags() {
    final baseFilter = ref.read(baseFilterProvider);
    setState(() {
      _selectedCategoryIds = List<String>.from(baseFilter.categoryIds);
      _selectedTagIds = List<String>.from(baseFilter.tagIds);
    });

    logDebug(
      'FilterModal: Загружены выбранные категории и теги',
      data: {
        'categories': _selectedCategoryIds.length,
        'tags': _selectedTagIds.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entityType = ref.watch(entityTypeProvider).currentType;
    final windowHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        minHeight: UniversalPlatform.isDesktop ? windowHeight * 0.8 : 0,
        maxHeight: UniversalPlatform.isDesktop
            ? windowHeight * 0.9
            : double.infinity,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Секция категорий
            _buildCategoriesSection(entityType),
            const SizedBox(height: 24),

            // Секция тегов
            _buildTagsSection(entityType),
            const SizedBox(height: 24),

            // Базовые фильтры
            _buildBaseFiltersSection(entityType),
            const SizedBox(height: 24),

            // Специфичные фильтры для типа сущности
            _buildSpecificFiltersSection(entityType),
            const SizedBox(height: 32),

            // Кнопки действий
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(EntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категории',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        CategoryPickerField(
          isFilter: true,
          selectedCategoryIds: _selectedCategoryIds,
          selectedCategoryNames: _selectedCategoryNames,
          filterByType: _getCategoryType(entityType),
          onCategoriesSelected: (ids, names) {
            setState(() {
              _selectedCategoryIds = ids;
              _selectedCategoryNames = names;
            });
            ref.read(baseFilterProvider.notifier).setCategoryIds(ids);
            logDebug(
              'FilterModal: Обновлены категории',
              data: {'count': ids.length},
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection(EntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Теги',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TagPickerField(
          isFilter: true,
          selectedTagIds: _selectedTagIds,
          selectedTagNames: _selectedTagNames,
          filterByType: _getTagType(entityType),
          onTagsSelected: (ids, names) {
            setState(() {
              _selectedTagIds = ids;
              _selectedTagNames = names;
            });
            ref.read(baseFilterProvider.notifier).setTagIds(ids);
            logDebug(
              'FilterModal: Обновлены теги',
              data: {'count': ids.length},
            );
          },
        ),
      ],
    );
  }

  Widget _buildBaseFiltersSection(EntityType entityType) {
    final baseFilter = ref.watch(baseFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Общие фильтры',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        BaseFilterSection(
          filter: baseFilter,
          entityTypeName: entityType.label,
          onFilterChanged: (updatedFilter) {
            // Обновление через notifier методы
            final notifier = ref.read(baseFilterProvider.notifier);
            notifier.setQuery(updatedFilter.query);
            notifier.setCategoryIds(updatedFilter.categoryIds);
            notifier.setTagIds(updatedFilter.tagIds);
            notifier.setFavorite(updatedFilter.isFavorite);
            notifier.setArchived(updatedFilter.isArchived);
            notifier.setDeleted(updatedFilter.isDeleted);
            notifier.setPinned(updatedFilter.isPinned);
            notifier.setHasNotes(updatedFilter.hasNotes);
            notifier.setCreatedAfter(updatedFilter.createdAfter);
            notifier.setCreatedBefore(updatedFilter.createdBefore);
            notifier.setModifiedAfter(updatedFilter.modifiedAfter);
            notifier.setModifiedBefore(updatedFilter.modifiedBefore);
            notifier.setLastAccessedAfter(updatedFilter.lastAccessedAfter);
            notifier.setLastAccessedBefore(updatedFilter.lastAccessedBefore);
            notifier.setMinUsedCount(updatedFilter.minUsedCount);
            notifier.setMaxUsedCount(updatedFilter.maxUsedCount);
            notifier.setSortDirection(updatedFilter.sortDirection);
          },
        ),
      ],
    );
  }

  Widget _buildSpecificFiltersSection(EntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтры ${entityType.label.toLowerCase()}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildEntitySpecificSection(entityType),
      ],
    );
  }

  Widget _buildEntitySpecificSection(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        final passwordFilter = ref.watch(passwordsFilterProvider);
        return PasswordFilterSection(
          filter: passwordFilter,
          onFilterChanged: (updatedFilter) {
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilterDebounced(updatedFilter);
          },
        );

      case EntityType.note:
        final notesFilter = ref.watch(notesFilterProvider);
        return NotesFilterSection(
          filter: notesFilter,
          onFilterChanged: (updatedFilter) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilterDebounced(updatedFilter);
          },
        );

      case EntityType.otp:
        final otpFilter = ref.watch(otpsFilterProvider);
        return OtpsFilterSection(
          filter: otpFilter,
          onFilterChanged: (updatedFilter) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilterDebounced(updatedFilter);
          },
        );

      case EntityType.bankCard:
        final bankCardsFilter = ref.watch(bankCardsFilterProvider);
        return BankCardsFilterSection(
          filter: bankCardsFilter,
          onFilterChanged: (updatedFilter) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilterDebounced(updatedFilter);
          },
        );

      case EntityType.file:
        final filesFilter = ref.watch(filesFilterProvider);
        return FilesFilterSection(
          filter: filesFilter,
          onFilterChanged: (updatedFilter) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilterDebounced(updatedFilter);
          },
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final baseFilter = ref.watch(baseFilterProvider);
    final hasActiveFilters = baseFilter.hasActiveConstraints;

    return Row(
      children: [
        // Кнопка сброса
        if (hasActiveFilters)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Сбросить все'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (hasActiveFilters) const SizedBox(width: 12),

        // Кнопка применения
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _applyFilters(context),
            icon: const Icon(Icons.check),
            label: const Text('Применить'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  CategoryType _getCategoryType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return CategoryType.password;
      case EntityType.note:
        return CategoryType.notes;
      case EntityType.bankCard:
        return CategoryType.bankCard;
      case EntityType.file:
        return CategoryType.files;
      case EntityType.otp:
        return CategoryType.totp;
    }
  }

  TagType _getTagType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return TagType.password;
      case EntityType.note:
        return TagType.notes;
      case EntityType.bankCard:
        return TagType.bankCard;
      case EntityType.file:
        return TagType.files;
      case EntityType.otp:
        return TagType.totp;
    }
  }

  void _resetFilters() {
    logDebug('FilterModal: Сброс всех фильтров');

    try {
      final entityType = ref.read(entityTypeProvider).currentType;

      // Сброс базового фильтра
      ref.read(baseFilterProvider.notifier).reset();

      // Сброс специфичного для типа фильтра
      switch (entityType) {
        case EntityType.password:
          ref.read(passwordsFilterProvider.notifier).reset();
          break;
        case EntityType.note:
          ref.read(notesFilterProvider.notifier).reset();
          break;
        case EntityType.otp:
          ref.read(otpsFilterProvider.notifier).reset();
          break;
        case EntityType.bankCard:
          ref.read(bankCardsFilterProvider.notifier).reset();
          break;
        case EntityType.file:
          ref.read(filesFilterProvider.notifier).reset();
          break;
      }

      // Очистка локального состояния
      setState(() {
        _selectedCategoryIds = [];
        _selectedCategoryNames = [];
        _selectedTagIds = [];
        _selectedTagNames = [];
      });

      logInfo('FilterModal: Фильтры успешно сброшены');
    } catch (e) {
      logError('FilterModal: Ошибка при сбросе фильтров', error: e);
    }
  }

  /// Восстановить начальные значения фильтров (если нужен откат)
  /// Может быть использован для кнопки "Отменить изменения"
  // ignore: unused_element
  void _restoreInitialValues() {
    if (_initialValues == null) {
      logWarning(
        'FilterModal: Нет сохраненных начальных значений для восстановления',
      );
      return;
    }

    logDebug('FilterModal: Восстановление начальных значений фильтров');

    try {
      final entityType = ref.read(entityTypeProvider).currentType;

      // Восстановление базового фильтра через методы notifier
      final baseNotifier = ref.read(baseFilterProvider.notifier);
      final base = _initialValues!.baseFilter;

      baseNotifier.setQuery(base.query);
      baseNotifier.setCategoryIds(base.categoryIds);
      baseNotifier.setTagIds(base.tagIds);
      baseNotifier.setFavorite(base.isFavorite);
      baseNotifier.setArchived(base.isArchived);
      baseNotifier.setDeleted(base.isDeleted);
      baseNotifier.setPinned(base.isPinned);
      baseNotifier.setHasNotes(base.hasNotes);
      baseNotifier.setCreatedAfter(base.createdAfter);
      baseNotifier.setCreatedBefore(base.createdBefore);
      baseNotifier.setModifiedAfter(base.modifiedAfter);
      baseNotifier.setModifiedBefore(base.modifiedBefore);
      baseNotifier.setLastAccessedAfter(base.lastAccessedAfter);
      baseNotifier.setLastAccessedBefore(base.lastAccessedBefore);
      baseNotifier.setMinUsedCount(base.minUsedCount);
      baseNotifier.setMaxUsedCount(base.maxUsedCount);
      baseNotifier.setSortDirection(base.sortDirection);

      // Восстановление специфичного для типа фильтра
      switch (entityType) {
        case EntityType.password:
          if (_initialValues!.passwordsFilter != null) {
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.passwordsFilter!);
          }
          break;
        case EntityType.note:
          if (_initialValues!.notesFilter != null) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.notesFilter!);
          }
          break;
        case EntityType.otp:
          if (_initialValues!.otpsFilter != null) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.otpsFilter!);
          }
          break;
        case EntityType.bankCard:
          if (_initialValues!.bankCardsFilter != null) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.bankCardsFilter!);
          }
          break;
        case EntityType.file:
          if (_initialValues!.filesFilter != null) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.filesFilter!);
          }
          break;
      }

      // Восстановление локального состояния
      setState(() {
        _selectedCategoryIds = List<String>.from(base.categoryIds);
        _selectedTagIds = List<String>.from(base.tagIds);
      });

      logInfo('FilterModal: Начальные значения восстановлены');
    } catch (e) {
      logError(
        'FilterModal: Ошибка при восстановлении начальных значений',
        error: e,
      );
    }
  }

  void _applyFilters(BuildContext context) {
    logDebug('FilterModal: Применение фильтров');

    try {
      widget.onFilterApplied?.call();
      Navigator.of(context).pop();
      logInfo('FilterModal: Фильтры применены');
    } catch (e) {
      logError('FilterModal: Ошибка при применении фильтров', error: e);
    }
  }
}

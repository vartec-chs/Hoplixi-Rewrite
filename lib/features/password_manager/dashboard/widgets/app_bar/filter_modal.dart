import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

// Модели и провайдеры
import '../../models/entity_type.dart';
import '../../providers/entity_type_provider.dart';
import '../../providers/filter_providers/base_filter_provider.dart';
import '../../providers/filter_providers/password_filter_provider.dart';
import '../../providers/filter_providers/notes_filter_provider.dart';
import '../../providers/filter_providers/otp_filter_provider.dart';
import '../../providers/filter_providers/bank_cards_filter_provider.dart';
import '../../providers/filter_providers/files_filter_provider.dart';

// Секции фильтров
import '../filter_sections/filter_sections.dart';

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
      // modalTypeBuilder: (context) {
      //   // Адаптивный тип модалки в зависимости от размера экрана
      //   final size = MediaQuery.of(context).size;
      //   if (size.width < 768) {
      //     return WoltModalType.bottomSheet();
      //   } else {
      //     return WoltModalType.dialog();
      //   }
      // },
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
      trailingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Закрыть',
      ),
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

  // Хранение начальных значений для отката
  Map<String, dynamic> _initialValues = {};

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

    _initialValues = {
      'categoryIds': List<String>.from(baseFilter.categoryIds),
      'tagIds': List<String>.from(baseFilter.tagIds),
      'query': baseFilter.query,
      'isFavorite': baseFilter.isFavorite,
      'isArchived': baseFilter.isArchived,
      'isDeleted': baseFilter.isDeleted,
      'isPinned': baseFilter.isPinned,
      'hasNotes': baseFilter.hasNotes,
      'createdAfter': baseFilter.createdAfter,
      'createdBefore': baseFilter.createdBefore,
      'modifiedAfter': baseFilter.modifiedAfter,
      'modifiedBefore': baseFilter.modifiedBefore,
      'lastAccessedAfter': baseFilter.lastAccessedAfter,
      'lastAccessedBefore': baseFilter.lastAccessedBefore,
      'minUsedCount': baseFilter.minUsedCount,
      'maxUsedCount': baseFilter.maxUsedCount,
      'sortDirection': baseFilter.sortDirection,
      'limit': baseFilter.limit,
      'offset': baseFilter.offset,
    };

    // Сохраняем специфичные для типа значения
    switch (entityType) {
      case EntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        _initialValues.addAll({
          'password_name': passwordFilter.name,
          'password_login': passwordFilter.login,
          'password_email': passwordFilter.email,
          'password_url': passwordFilter.url,
          'password_hasDescription': passwordFilter.hasDescription,
          'password_hasUrl': passwordFilter.hasUrl,
          'password_hasLogin': passwordFilter.hasLogin,
          'password_hasEmail': passwordFilter.hasEmail,
          'password_sortField': passwordFilter.sortField,
        });
        break;

      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        _initialValues.addAll({
          'notes_title': notesFilter.title,
          'notes_content': notesFilter.content,
          'notes_hasDescription': notesFilter.hasDescription,
          'notes_hasDeltaJson': notesFilter.hasDeltaJson,
          'notes_minContentLength': notesFilter.minContentLength,
          'notes_maxContentLength': notesFilter.maxContentLength,
          'notes_sortField': notesFilter.sortField,
        });
        break;

      case EntityType.otp:
        final otpFilter = ref.read(otpsFilterProvider);
        _initialValues.addAll({
          'otp_issuer': otpFilter.issuer,
          'otp_accountName': otpFilter.accountName,
          'otp_types': List<String>.from(otpFilter.types),
          'otp_algorithms': List<String>.from(otpFilter.algorithms),
          'otp_secretEncodings': List<String>.from(otpFilter.secretEncodings),
          'otp_digits': List<int>.from(otpFilter.digits),
          'otp_periods': List<int>.from(otpFilter.periods),
          'otp_hasPasswordLink': otpFilter.hasPasswordLink,
          'otp_sortField': otpFilter.sortField,
        });
        break;

      case EntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        _initialValues.addAll({
          'bankCard_bankName': bankCardsFilter.bankName,
          'bankCard_cardholderName': bankCardsFilter.cardholderName,
          'bankCard_cardTypes': List<String>.from(bankCardsFilter.cardTypes),
          'bankCard_cardNetworks': List<String>.from(
            bankCardsFilter.cardNetworks,
          ),
          'bankCard_hasExpiryDatePassed': bankCardsFilter.hasExpiryDatePassed,
          'bankCard_isExpiringSoon': bankCardsFilter.isExpiringSoon,
          'bankCard_sortField': bankCardsFilter.sortField,
        });
        break;

      case EntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        _initialValues.addAll({
          'file_fileName': filesFilter.fileName,
          'file_fileExtensions': List<String>.from(filesFilter.fileExtensions),
          'file_mimeTypes': List<String>.from(filesFilter.mimeTypes),
          'file_minFileSize': filesFilter.minFileSize,
          'file_maxFileSize': filesFilter.maxFileSize,
          'file_sortField': filesFilter.sortField,
        });
        break;
    }

    logDebug(
      'FilterModal: Сохранены начальные значения',
      data: {'entityType': entityType.id, 'valuesCount': _initialValues.length},
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
    final theme = Theme.of(context);
    final entityType = ref.watch(entityTypeProvider).currentType;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
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
    final theme = Theme.of(context);
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

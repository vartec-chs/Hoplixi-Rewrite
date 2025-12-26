import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/notes_filter.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Результат выбора заметки
class NotePickerResult {
  final String id;
  final String name;

  const NotePickerResult({required this.id, required this.name});
}

/// Состояние данных заметок
class NotePickerData {
  final List<NoteCardDto> notes;
  final bool hasMore;
  final bool isLoadingMore;

  const NotePickerData({
    this.notes = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  NotePickerData copyWith({
    List<NoteCardDto>? notes,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotePickerData(
      notes: notes ?? this.notes,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ====== PROVIDERS ======

const int _pageSize = 20;

/// Provider для фильтра заметок
final notePickerFilterProvider =
    NotifierProvider<NotePickerFilterNotifier, NotesFilter>(
      NotePickerFilterNotifier.new,
    );

class NotePickerFilterNotifier extends Notifier<NotesFilter> {
  @override
  NotesFilter build() {
    return NotesFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: _pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NotesSortField.modifiedAt,
    );
  }

  /// Обновить поисковый запрос
  void updateQuery(String query) {
    state = state.copyWith(
      base: state.base.copyWith(query: query.trim(), offset: 0),
    );
  }

  /// Увеличить offset для пагинации
  void incrementOffset() {
    state = state.copyWith(
      base: state.base.copyWith(offset: (state.base.offset ?? 0) + _pageSize),
    );
  }

  /// Сбросить фильтр
  void reset() {
    state = NotesFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: _pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NotesSortField.modifiedAt,
    );
  }
}

/// Provider для загруженных данных заметок
final notePickerDataProvider =
    NotifierProvider<NotePickerDataNotifier, NotePickerData>(
      NotePickerDataNotifier.new,
    );

class NotePickerDataNotifier extends Notifier<NotePickerData> {
  @override
  NotePickerData build() {
    return const NotePickerData();
  }

  /// Загрузить первую страницу заметок
  Future<void> loadInitial() async {
    final filter = ref.read(notePickerFilterProvider);
    final mainStoreAsync = ref.read(mainStoreProvider);

    final mainStore = mainStoreAsync.value;
    if (mainStore == null || !mainStore.isOpen) {
      Toaster.error(title: 'Ошибка', description: 'База данных не открыта');
      return;
    }

    try {
      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) {
        Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
        return;
      }

      final dao = manager.currentStore!.noteFilterDao;
      final notes = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      state = NotePickerData(
        notes: notes,
        hasMore: notes.length < total,
        isLoadingMore: false,
      );
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  /// Загрузить следующую страницу заметок
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final mainStoreAsync = ref.read(mainStoreProvider);

    final mainStore = mainStoreAsync.value;
    if (mainStore == null || !mainStore.isOpen) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      // Увеличиваем offset
      ref.read(notePickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(notePickerFilterProvider);

      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final dao = manager.currentStore!.noteFilterDao;
      final newNotes = await dao.getFiltered(updatedFilter);
      final total = await dao.countFiltered(updatedFilter);

      final allNotes = [...state.notes, ...newNotes];

      state = NotePickerData(
        notes: allNotes,
        hasMore: allNotes.length < total,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }
}

// ====== MODAL WIDGET ======

/// Показать модальное окно выбора заметки
Future<NotePickerResult?> showNotePickerModal(
  BuildContext context,
  WidgetRef ref,
) async {
  // Сбрасываем состояние перед показом
  ref.read(notePickerFilterProvider.notifier).reset();
  ref.invalidate(notePickerDataProvider);

  // Загружаем начальные данные
  await ref.read(notePickerDataProvider.notifier).loadInitial();

  if (!context.mounted) return null;

  return await WoltModalSheet.show<NotePickerResult>(
    context: context,
    pageListBuilder: (context) => [_buildNotePickerPage(context, ref)],
    modalTypeBuilder: (context) {
      return WoltModalType.dialog();
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

/// Построить страницу модального окна
WoltModalSheetPage _buildNotePickerPage(BuildContext context, WidgetRef ref) {
  return WoltModalSheetPage(
    backgroundColor: Theme.of(context).colorScheme.surface,
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать заметку',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: const _NotePickerContent(),
  );
}

/// Контент модального окна
class _NotePickerContent extends ConsumerStatefulWidget {
  const _NotePickerContent();

  @override
  ConsumerState<_NotePickerContent> createState() => _NotePickerContentState();
}

class _NotePickerContentState extends ConsumerState<_NotePickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notePickerDataProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(notePickerFilterProvider.notifier).updateQuery(value);
    ref.read(notePickerDataProvider.notifier).loadInitial();
  }

  void _onNoteSelected(NoteCardDto note) {
    Navigator.of(context).pop(NotePickerResult(id: note.id, name: note.title));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(notePickerDataProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Поле поиска
          TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название заметки',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),

          // Список заметок
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: data.notes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Заметки не найдены'),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: data.notes.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == data.notes.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final note = data.notes[index];
                      return _NoteListTile(
                        note: note,
                        onTap: () => _onNoteSelected(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Элемент списка заметок
class _NoteListTile extends StatelessWidget {
  final NoteCardDto note;
  final VoidCallback onTap;

  const _NoteListTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        note.title,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: note.description != null
          ? Text(
              note.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.note,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      trailing: note.isFavorite
          ? Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}

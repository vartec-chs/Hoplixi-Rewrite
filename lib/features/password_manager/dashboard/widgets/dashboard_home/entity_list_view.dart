// // ---------- EntityListView: пагинация + footer + overlay ----------
// class _EntityListViewState extends ConsumerState<EntityListView> {
//   late final ScrollController _scrollController;
//   static const _kScrollThreshold = 200.0;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = widget.scrollController ?? ScrollController();
//     _scrollController.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     if (widget.scrollController == null) _scrollController.dispose();
//     else _scrollController.removeListener(_onScroll);
//     super.dispose();
//   }

//   void _onScroll() {
//     if (!_scrollController.hasClients) return;
//     final pos = _scrollController.position;
//     if (pos.pixels >= pos.maxScrollExtent - _kScrollThreshold) {
//       _tryLoadMore();
//     }
//   }

//   // Универсальная защита: по текущему entityType проверяем состояние и вызываем loadMore только когда можно
//   void _tryLoadMore() {
//     final type = ref.read(currentEntityTypeProvider);
//     switch (type) {
//       case EntityType.password:
//         final av = ref.read(paginatedPasswordsProvider);
//         av.when(
//           data: (s) {
//             final st = s as dynamic;
//             if (!st.isLoadingMore && st.hasMore && !st.isLoading) {
//               ref.read(paginatedPasswordsProvider.notifier).loadMore();
//             }
//           },
//           loading: () {},
//           error: (_, __) {},
//         );
//         break;
//       case EntityType.otp:
//         final av = ref.read(paginatedOtpsProvider);
//         av.when(
//           data: (s) {
//             final st = s as dynamic;
//             if (!st.isLoadingMore && st.hasMore && !st.isLoading) {
//               ref.read(paginatedOtpsProvider.notifier).loadMore();
//             }
//           },
//           loading: () {},
//           error: (_, __) {},
//         );
//         break;
//       case EntityType.note:
//         final av = ref.read(paginatedNotesProvider);
//         av.when(
//           data: (s) {
//             final st = s as dynamic;
//             if (!st.isLoadingMore && st.hasMore && !st.isLoading) {
//               ref.read(paginatedNotesProvider.notifier).loadMore();
//             }
//           },
//           loading: () {},
//           error: (_, __) {},
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final entityType = ref.watch(currentEntityTypeProvider);
//     final viewMode = ref.watch(currentViewModeProvider);

//     // Получаем AsyncValue текущего типа, и state (динамически)
//     final async = _asyncFor(entityType);

//     return RefreshIndicator( // pull-to-refresh для всего списка
//       onRefresh: () async {
//         switch (entityType) {
//           case EntityType.password:
//             await ref.read(paginatedPasswordsProvider.notifier).refresh();
//             break;
//           case EntityType.otp:
//             await ref.read(paginatedOtpsProvider.notifier).refresh();
//             break;
//           case EntityType.note:
//             await ref.read(paginatedNotesProvider.notifier).refresh();
//             break;
//         }
//       },
//       child: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverToBoxAdapter(child: _buildToolbar(entityType, viewMode)),
//           // Контент - когда async.loading -> показываем overlay ниже
//           async.when(
//             loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
//             error: (err, _) => SliverFillRemaining(child: Center(child: Text('Ошибка: $err'))),
//             data: (state) {
//               final items = _extractItems(state);
//               final isLoadingMore = (state as dynamic).isLoadingMore as bool;
//               final hasMore = (state as dynamic).hasMore as bool;

//               // Сам универсальный список (параметры под твои карточки)
//               final listSliver = EntitySliverList(
//                 items: items,
//                 viewMode: viewMode,
//                 listBuilder: (ctx, item) => _buildListCardFor(item),
//                 gridBuilder: (ctx, item) => _buildGridCardFor(item),
//                 itemBorderRadius: 12.0,
//               );

//               // Если подгружаем — добавляем footer Sliver с индикатором
//               final footer = isLoadingMore
//                   ? const SliverToBoxAdapter(
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
//                       ),
//                     )
//                   : hasMore
//                       ? const SliverToBoxAdapter(child: SizedBox(height: 8)) // немного пространства, но ничего
//                       : const SliverToBoxAdapter(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(vertical: 20),
//                             child: Center(child: Text('Больше нет данных')),
//                           ),
//                         );

//               // Если state.isLoading (initial load) — можно показать overlay путем SliverStack
//               final isInitialLoading = (state as dynamic).isLoading as bool;
//               if (isInitialLoading) {
//                 return SliverStack(children: [
//                   listSliver,
//                   const SliverFillRemaining(
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(color: Colors.black38),
//                       child: Center(child: CircularProgressIndicator()),
//                     ),
//                   ),
//                 ]);
//               }

//               // Обычная ситуация: список + footer
//               return MultiSliver(children: [listSliver, footer]);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // Вспомогалки — подставь свои builders
//   Widget _buildListCardFor(dynamic item) {
//     // предполагаем, что listBuilder возвращает полноценную карточку без ClipRRect т.к. EntitySliverList уже оборачивает
//     // тут можно возвращать реальную PasswordListCard, NoteListCard и т.д.
//     return Text('TODO: реализуй listCard');
//   }

//   Widget _buildGridCardFor(dynamic item) {
//     return Text('TODO: реализуй gridCard');
//   }

//   AsyncValue _asyncFor(EntityType type) {
//     switch (type) {
//       case EntityType.password:
//         return ref.watch(paginatedPasswordsProvider);
//       case EntityType.otp:
//         return ref.watch(paginatedOtpsProvider);
//       case EntityType.note:
//         return ref.watch(paginatedNotesProvider);
//     }
//   }

//   List _extractItems(dynamic state) {
//     if (state == null) return [];
//     final dynamic s = state;
//     if (s.passwords != null) return s.passwords as List;
//     if (s.otps != null) return s.otps as List;
//     if (s.notes != null) return s.notes as List;
//     return [];
//   }

//   SliverToBoxAdapter _buildToolbar(EntityType entityType, ViewMode viewMode) {
//     return SliverToBoxAdapter(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Row(
//           children: [
//             Expanded(child: Text(_titleForEntity(entityType), style: Theme.of(context).textTheme.titleMedium)),
//             ToggleButtons(
//               isSelected: [viewMode == ViewMode.list, viewMode == ViewMode.grid],
//               onPressed: (i) => ref.read(currentViewModeProvider.notifier).state = i == 0 ? ViewMode.list : ViewMode.grid,
//               children: const [Icon(Icons.view_list), Icon(Icons.grid_view)],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _titleForEntity(EntityType type) {
//     switch (type) {
//       case EntityType.password:
//         return 'Пароли';
//       case EntityType.otp:
//         return 'OTP';
//       case EntityType.note:
//         return 'Заметки';
//     }
//   }
// }

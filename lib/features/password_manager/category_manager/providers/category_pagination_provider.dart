import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Провайдер для загрузки страницы категорий
final categoryPageProvider = FutureProvider.autoDispose
    .family<List<CategoryCardDto>, ({CategoriesFilter filter, int pageKey})>((
      ref,
      params,
    ) async {
      final dao = await ref.watch(categoryDaoProvider.future);

      // Вычисляем offset
      final offset = params.pageKey * (params.filter.limit ?? 20);

      // Создаем фильтр с правильным offset
      final pageFilter = params.filter.copyWith(offset: offset);

      // Получаем категории
      return await dao.getCategoryCardsFiltered(pageFilter);
    });

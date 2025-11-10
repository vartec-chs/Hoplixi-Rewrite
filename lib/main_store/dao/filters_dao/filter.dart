/// Общий контракт для DAO, возвращающих отфильтрованные DTO и их количество.
abstract class FilterDao<TFilter, TDto> {
  /// Возвращает список DTO по фильтру.
  Future<List<TDto>> getFiltered(TFilter filter);

  /// Считает количество элементов по фильтру.
  Future<int> countFiltered(TFilter filter);
}

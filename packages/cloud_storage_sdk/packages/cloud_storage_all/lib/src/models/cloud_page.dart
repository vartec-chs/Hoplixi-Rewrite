class CloudPage<T> {
  final List<T> items;
  final String? nextToken;

  const CloudPage({required this.items, this.nextToken});

  bool get hasMore => (nextToken?.isNotEmpty ?? false);
}

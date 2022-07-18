class PaginationPage<T> {
  const PaginationPage({
    required this.index,
    required this.size,
    required this.numberOfPages,
    required this.items,
  });

  final int index;
  final int size;
  final int numberOfPages;
  final List<T> items;
}

extension ListExtensions<T> on Iterable<T> {
  Iterable<T> distinct() sync* {
    final set = <T>{};
    for (final item in this) {
      if (!set.contains(item)) {
        set.add(item);
        yield item;
      }
    }
  }
}

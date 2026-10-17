extension CollectionExtensions<T> on Iterable<T> {
  Map<K, V> toMap<K, V>((K, V) Function(T) selector) {
    final map = <K, V>{};
    for (final element in this) {
      final (k, v) = selector(element);
      map[k] = v;
    }
    return map;
  }
}

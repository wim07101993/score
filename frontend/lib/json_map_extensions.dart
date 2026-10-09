/// Reading what the API and the store hand over: JSON, which says nothing
/// about what a value is until it is asked.
library;

extension JsonMapExtensions on Map {
  T? get<T>(dynamic key, {T? Function(String)? parser}) {
    final value = this[key];
    return switch (value) {
      final T t => t,
      final String s => parser == null ? null : parser(s),
      _ => null,
    };
  }

  T? getObject<T>(dynamic key, T? Function(Map) mapper) {
    final map = get<Map>(key);
    if (map == null) {
      return null;
    }
    return mapper(map);
  }

  List<T> getList<T>(dynamic key) {
    final list = get<List>(key);
    if (list == null) {
      return const [];
    }
    return list.whereType<T>().toList(growable: false);
  }
}

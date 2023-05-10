extension JsonExtensions on Map<String, dynamic> {
  T get<T>(String key) {
    final value = maybeGet(key);
    if (value is T) {
      return value;
    } else {
      throw Exception('Could not find $key in map');
    }
  }

  T? maybeGet<T>(String key) {
    final value = this[key];
    if (value is T?) {
      return value;
    } else {
      throw Exception(
        'Value for $key is not of type $T ($value of type ${value.runtimeType})',
      );
    }
  }

  List<T> getList<T>(String key) {
    return maybeGet<List>(key)?.whereType<T>().toList(growable: false) ??
        const [];
  }

  Map<TKey, TValue> getMap<TKey, TValue>(String key) {
    return maybeGet<Map<TKey, TValue>>(key) ?? const {};
  }

  T getObject<T>(String key, T Function(Map<String, dynamic> json) parser) {
    return parser(getMap<String, dynamic>(key));
  }

  List<T> getObjectList<T>(
    String key,
    T Function(Map<String, dynamic> json) parser,
  ) {
    return getList<Map<String, dynamic>>(key)
        .map(parser)
        .toList(growable: false);
  }
}

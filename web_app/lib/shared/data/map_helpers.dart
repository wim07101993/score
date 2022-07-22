extension JsonMapHelperExtensions on Map<String, dynamic> {
  T? maybeGet<T>(String key) => this[key] as T?;

  DateTime? maybeGetDateTime(String key) {
    final milliseconds = this[key] as int?;
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Iterable<T>? maybeGetList<T>(String key) {
    return maybeGet<List>(key)?.whereType<T>();
  }

  Iterable<T>? maybeGetListConverted<T>(
    String key,
    T? Function(Map<String, dynamic> json) converter,
  ) {
    return maybeGetList<Map<String, dynamic>>(key)
        ?.map(converter)
        .whereType<T>();
  }
}

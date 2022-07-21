extension JsonMapHelperExtensions on Map<String, dynamic> {
  List<T>? maybeGetList<T>(String key) {
    return (this[key] as List<dynamic>?)?.cast<T>();
  }

  List<T> getList<T>(String key) => (this[key] as List<dynamic>).cast<T>();

  T? maybeGet<T>(String key) => this[key] as T?;

  T get<T>(String key) => this[key] as T;

  DateTime? maybeGetDateTime(String key) {
    final milliseconds = this[key] as int?;
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}

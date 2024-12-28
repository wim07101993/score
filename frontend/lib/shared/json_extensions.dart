extension JsonExtensions on Map<String, dynamic> {
  T? get<T>(String key) {
    final value = this[key];
    if (value is T) {
      return value;
    }
    if (T == Uri && value is String) {
      return Uri.tryParse(value) as T?;
    }
    return null;
  }
}

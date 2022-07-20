extension MapHelperExtensions on Map<String, dynamic> {
  List<T>? getList<T>(String key) {
    return (this[key] as List<dynamic>?)?.cast<T>();
  }

  DateTime? getDateTime(String key) {
    final milliseconds = this[key] as int?;
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}

class AggregateException implements Exception {
  const AggregateException(this.errors);

  final List errors;

  @override
  String toString() {
    return errors.join("\n");
  }
}

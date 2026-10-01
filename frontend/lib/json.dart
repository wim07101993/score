/// Reading what the API and the store hand over: JSON, which says nothing
/// about what a value is until it is asked.
library;

/// A moment, or null for anything that is not one.
///
/// A moment is written as RFC 3339 — the API's are in UTC, and so are the ones
/// this app stores — so what is read back is the moment that was written,
/// whatever zone the device is in.
DateTime? dateOf(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// A list of text, and none for anything that is not a list.
List<String> stringsOf(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

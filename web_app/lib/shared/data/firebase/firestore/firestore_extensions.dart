import 'package:cloud_firestore/cloud_firestore.dart';

extension CorruptDataExtensions on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> get _corruptData {
    return collection('corruptData');
  }

  Future<void> reportCorruptData(Map<String, dynamic>? data) {
    return data == null ? Future.value() : _corruptData.add(data);
  }
}

extension DocumentSnapshotExtensions on DocumentSnapshot<Map<String, dynamic>> {
  T? maybeGet<T>(Object field) => get(field) as T?;

  DateTime? maybeGetDateTime(Object field) {
    final timestamp = maybeGet<Timestamp>(field);
    if (timestamp == null) {
      return null;
    }
    return DateTime.fromMicrosecondsSinceEpoch(
      timestamp.microsecondsSinceEpoch,
    );
  }

  Iterable<T>? maybeGetList<T>(Object field) {
    return maybeGet<List>(field)?.whereType<T>();
  }

  Iterable<T>? maybeGetListConverted<T>(
    Object field,
    T? Function(Map<String, dynamic> json) maybeConverter,
  ) {
    return maybeGetList<Map<String, dynamic>>(field)
        ?.map(maybeConverter)
        .whereType<T>();
  }
}

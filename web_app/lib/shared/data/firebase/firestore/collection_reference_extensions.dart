import 'package:cloud_firestore/cloud_firestore.dart';

extension ScoresFirestoreExtensions<T> on CollectionReference<T> {
  Future<Iterable<T>> page(int pageSize, int pageIndex) async {
    final startIndex = pageIndex * pageSize;
    // final endIndex = startIndex + pageSize;
    final snapshot = await orderBy('modifiedAt').startAt([startIndex])
        // .endAt([endIndex])
        .get();
    return snapshot.docs.map((e) => e.data());
  }
}

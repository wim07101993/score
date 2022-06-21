import 'package:cloud_firestore/cloud_firestore.dart';

extension QueryExtensions<T> on Query<T> {
  Query<T> page(int pageSize, int pageIndex) {
    final startIndex = pageIndex * pageSize;
    // final endIndex = startIndex + pageSize;
    return startAt([startIndex]);
    // .endAt([endIndex]);
  }

  Future<List<T>> get items {
    return get().then((s) => s.docs.map((doc) => doc.data()).toList());
  }
}

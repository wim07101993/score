import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/firestore_extensions.dart';
import 'package:score/shared/models/score.dart';

extension ScoresFirestoreExtensions
    on CollectionReference<Map<String, dynamic>> {
  Future<Iterable<Score>> page(int pageSize, int pageIndex) async {
    final startIndex = pageIndex * pageSize;
    final endIndex = startIndex + pageSize;
    final snapshot = await orderBy('modifiedAt')
        .startAt([startIndex]).endAt([endIndex]).get();
    return snapshot.docs.map((s) => s.toScore());
  }
}

extension _QuerySnapshotExtensions
    on QueryDocumentSnapshot<Map<String, dynamic>> {
  Score toScore() => FirestoreScore._(this);
}

class FirestoreScore implements Score {
  FirestoreScore._(this.document);

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  String get title => document.field<String>('title');

  @override
  String? get subtitle => document.field<String?>('subtitle');

  @override
  String? get dedication => document.field<String?>('dedication');

  @override
  List<String> get composers => document.field<List<String>>('composers');

  @override
  DateTime get createdAt => document.field<DateTime>('createdAt');

  @override
  DateTime get modifiedAt => document.field<DateTime>('modifiedAt');
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/shared/data/firebase/firestore_extensions.dart';

extension ScoresFirestoreExtensions
    on CollectionReference<Map<String, dynamic>> {
  Future<Iterable<Score>> page(int pageSize, int pageIndex) async {
    final startIndex = pageIndex * pageSize;
    final endIndex = startIndex + pageSize;
    final snapshot = await orderBy('modifiedAt')
        .startAt([startIndex]).endAt([endIndex]).get();
    return snapshot.docs.map((document) => _FirestoreScore._(document));
  }
}

class _FirestoreScore implements Score {
  _FirestoreScore._(this.document);

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  String get id => document.id;

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

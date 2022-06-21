import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/models/score.dart';

extension FirestoreExtensions on FirebaseFirestore {
  static const String _titleName = 'title';
  static const String _subtitleName = 'subtitle';
  static const String _dedicationName = 'dedication';
  static const String _createdAtName = 'createdAt';
  static const String _modifiedAtName = 'modifiedAtName';
  static const String _composersName = 'composers';

  CollectionReference<Score> get scoreCollection {
    return collection('scores').withConverter<Score>(
      fromFirestore: (doc, options) => Score(
        title: doc.field<String>(_titleName),
        subtitle: doc.field<String?>(_subtitleName),
        dedication: doc.field<String?>(_dedicationName),
        createdAt: doc.field<DateTime>(_createdAtName),
        modifiedAt: doc.field<DateTime>(_modifiedAtName),
        composers: doc.field<List<String>>(_composersName),
      ),
      toFirestore: (score, options) => {
        _titleName: score.title,
        if (score.subtitle != null) _subtitleName: score.subtitle,
        if (score.dedication != null) _dedicationName: score.dedication,
        _createdAtName: score.createdAt,
        _modifiedAtName: score.modifiedAt,
        _composersName: score.composers,
      },
    );
  }
}

extension DocumentSnapshotExtensions on DocumentSnapshot<Map<String, dynamic>> {
  T field<T>(String name) => this[name] as T;
}

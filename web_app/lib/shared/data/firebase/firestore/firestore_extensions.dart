import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/models/score.dart';

extension FirestoreExtensions on FirebaseFirestore {
  static const String _titleName = 'title';
  static const String _subtitleName = 'subtitle';
  static const String _dedicationName = 'dedication';
  static const String _createdAtName = 'createdAt';
  static const String _modifiedAtName = 'modifiedAt';
  static const String _composersName = 'composers';

  CollectionReference<Score> get scoreCollection {
    return collection('scores').withConverter<Score>(
      fromFirestore: (doc, options) => Score(
        title: doc.getString(_titleName),
        subtitle: doc.getNullableString(_subtitleName),
        dedication: doc.getNullableString(_dedicationName),
        createdAt: doc.getDateTime(_createdAtName),
        modifiedAt: doc.getDateTime(_modifiedAtName),
        composers: doc.getListOfString(_composersName),
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

extension _DocumentSnapshotExtensions
    on DocumentSnapshot<Map<String, dynamic>> {
  String getString(Object field) => get(field) as String;
  String? getNullableString(Object field) => get(field) as String?;

  DateTime getDateTime(Object field) {
    final timestamp = get(field) as Timestamp;
    return DateTime.fromMicrosecondsSinceEpoch(
        timestamp.microsecondsSinceEpoch);
  }

  List<String> getListOfString(Object field) {
    return (get(field) as List).cast<String>();
  }
}

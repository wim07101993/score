import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/firestore/firestore_model_field_names.dart';
import 'package:score/shared/data/firebase/firestore/query_extensions.dart';
import 'package:score/shared/data/models/score.dart';
import 'package:score/shared/data/models/score_access_history_item.dart';

extension FirestoreExtensions on FirebaseFirestore {
  CollectionReference<Score> get scoresCollection {
    return collection('scores').withConverter<Score>(
      fromFirestore: (doc, options) => Score(
        id: doc.id,
        title: doc.getString(ScoreFields.title),
        subtitle: doc.getNullableString(ScoreFields.subtitle),
        dedication: doc.getNullableString(ScoreFields.dedication),
        createdAt: doc.getDateTime(ScoreFields.createdAt),
        modifiedAt: doc.getDateTime(ScoreFields.modifiedAt),
        composers: doc.getListOfString(ScoreFields.composers),
      ),
      toFirestore: (score, options) => {
        if (score.subtitle != null) ScoreFields.subtitle: score.subtitle,
        if (score.dedication != null) ScoreFields.dedication: score.dedication,
        ScoreFields.createdAt: score.createdAt,
        ScoreFields.modifiedAt: score.modifiedAt,
        ScoreFields.composers: score.composers,
      },
    );
  }

  CollectionReference<ScoreAccessHistoryItem> scoreAccessHistoryCollection(
    String userId,
  ) {
    return collection('score-access-history').withConverter(
      fromFirestore: (doc, options) => ScoreAccessHistoryItem(
        scoreId: doc.getString(ScoreAccessHistoryItemFields.scoreId),
        accessDate: doc.getDateTime(ScoreAccessHistoryItemFields.accessDate),
      ),
      toFirestore: (scoreHistoryItem, options) => {
        ScoreAccessHistoryItemFields.userId: userId,
        ScoreAccessHistoryItemFields.scoreId: scoreHistoryItem.scoreId,
        ScoreAccessHistoryItemFields.accessDate: scoreHistoryItem.accessDate,
      },
    );
  }

  Query<Score> scores(int pageSize, int pageIndex) {
    return scoresCollection
        .orderBy(ScoreFields.modifiedAt)
        .page(pageSize, pageIndex);
  }

  Future<String> addScore(Score score) {
    return scoresCollection.add(score).then((ref) => ref.id);
  }

  Query<ScoreAccessHistoryItem> scoreAccessHistory(String userId) {
    return scoreAccessHistoryCollection(userId)
        .where(ScoreAccessHistoryItemFields.userId, isEqualTo: userId)
        .orderBy(ScoreAccessHistoryItemFields.accessDate);
  }
}

extension _DocumentSnapshotExtensions
    on DocumentSnapshot<Map<String, dynamic>> {
  String getString(Object field) => get(field) as String;
  String? getNullableString(Object field) => get(field) as String?;

  DateTime getDateTime(Object field) {
    final timestamp = get(field) as Timestamp;
    return DateTime.fromMicrosecondsSinceEpoch(
      timestamp.microsecondsSinceEpoch,
    );
  }

  List<String> getListOfString(Object field) {
    return (get(field) as List).cast<String>();
  }
}

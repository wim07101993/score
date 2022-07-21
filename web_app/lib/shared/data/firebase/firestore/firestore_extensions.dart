import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/firestore/firestore_model_field_names.dart';
import 'package:score/shared/data/firebase/firestore/query_extensions.dart';
import 'package:score/shared/data/map_helpers.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/models/score_access_history_item.dart';

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
          arrangements: doc
              .getListOfJson(ScoreFields.arrangements)
              .map((json) => json.toArrangement())
              .toList(growable: false),
          tags: doc.getListOfString(ScoreFields.tags)),
      toFirestore: (score, options) => {
        ScoreFields.title: score.title,
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

  Query<Score> scores({required int pageSize, required int pageIndex}) {
    return scoresCollection
        .orderBy(ScoreFields.modifiedAt)
        .page(pageSize: pageSize, pageIndex: pageIndex);
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

  List<Map<String, dynamic>> getListOfJson(Object field) {
    return (get(field) as List).cast<Map<String, dynamic>>();
  }
}

extension _JsonExtensions on Map<String, dynamic> {
  Arrangement toArrangement() {
    return Arrangement(
      name: get(ArrangementFields.name),
      arrangers: getList(ArrangementFields.arrangers),
      parts: getList<Map<String, dynamic>>(ArrangementFields.parts)
          .map((json) => json.toArrangementPart())
          .toList(growable: false),
    );
  }

  ArrangementPart toArrangementPart() {
    final targetInstrument =
        get<String>(ArrangementPartFields.targetInstrument);
  }
}

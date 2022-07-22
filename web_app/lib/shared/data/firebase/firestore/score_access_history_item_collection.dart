import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';
import 'package:score/shared/models/score_access_history_item.dart';

class ScoreAccessHistoryItemFields {
  static const String userId = 'userId';
  static const String accessDate = 'accessDate';
  static const String scoreId = 'scoreId';
}

extension ScoreAccessHistoryItemCollectionExtensions on FirebaseFirestore {
  CollectionReference<ScoreAccessHistoryItem> scoreAccessHistoryCollection(
    String userId,
  ) {
    return collection('score-access-history').withConverter(
      fromFirestore: _docToScoreAccessHistoryItem,
      toFirestore: (scoreHistoryItem, options) => _scoreHistoryItemToDoc(
        scoreHistoryItem,
        userId,
        options,
      ),
    );
  }

  ScoreAccessHistoryItem _docToScoreAccessHistoryItem(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final scoreId = doc.maybeGet<String>(ScoreAccessHistoryItemFields.scoreId);
    final accessDate =
        doc.maybeGet<DateTime>(ScoreAccessHistoryItemFields.accessDate);

    if (scoreId == null || accessDate == null) {
      reportCorruptData(doc.data());
    }

    return ScoreAccessHistoryItem(
      scoreId: scoreId ?? '',
      accessDate: accessDate ?? DateTime.fromMicrosecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> _scoreHistoryItemToDoc(
    ScoreAccessHistoryItem scoreHistoryItem,
    String userId,
    SetOptions? options,
  ) {
    return {
      ScoreAccessHistoryItemFields.userId: userId,
      ScoreAccessHistoryItemFields.scoreId: scoreHistoryItem.scoreId,
      ScoreAccessHistoryItemFields.accessDate: scoreHistoryItem.accessDate,
    };
  }

  Query<ScoreAccessHistoryItem> scoreAccessHistory(String userId) {
    return scoreAccessHistoryCollection(userId)
        .where(ScoreAccessHistoryItemFields.userId, isEqualTo: userId)
        .orderBy(ScoreAccessHistoryItemFields.accessDate);
  }
}

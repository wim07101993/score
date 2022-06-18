import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/new_score/models/draft_score.dart';
import 'package:score/shared/data/firebase/firestore_extensions.dart';

extension NewScoreFirestoreExtensions on FirebaseFirestore {
  Future<void> saveDraftScore(DraftScore draftScore) {
    return scoreCollection.add(draftScore.toDocument());
  }
}

extension _DraftScoreExtensions on DraftScore {
  Map<String, dynamic> toDocument() {
    return {
      'title': title,
      if (subtitle?.isNotEmpty == false) 'subtitle': subtitle,
      if (dedication?.isNotEmpty == false) 'dedication': dedication,
      'composers': composers,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}

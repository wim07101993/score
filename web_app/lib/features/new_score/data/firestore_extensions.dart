import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/new_score/models/draft_score.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';

extension NewScoreFirestoreExtensions on FirebaseFirestore {
  Future<void> saveDraftScore(DraftScore draftScore) {
    return scoreCollection.add(draftScore.toScore());
  }
}

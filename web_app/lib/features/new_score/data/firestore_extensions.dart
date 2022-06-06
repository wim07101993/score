import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/data/firebase/firestore_extensions.dart';
import 'package:score/features/new_score/models/draft_score.dart';

extension NewScoreFirestoreExtensions on FirebaseFirestore {
  Future<void> saveDraftScore(DraftScore draftScore) {
    return scoreCollection().add(draftScore.toDocument());
  }
}

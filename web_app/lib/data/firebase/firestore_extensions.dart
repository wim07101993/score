import 'package:cloud_firestore/cloud_firestore.dart';

extension FirestoreExtensions on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> get scoreCollection {
    return collection('scores');
  }
}

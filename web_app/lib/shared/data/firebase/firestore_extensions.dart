import 'package:cloud_firestore/cloud_firestore.dart';

extension FirestoreExtensions on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> get scoreCollection {
    return collection('scores');
  }
}

extension QuerySnapshotExtensions
    on QueryDocumentSnapshot<Map<String, dynamic>> {
  T field<T>(String name) => this[name] as T;
}

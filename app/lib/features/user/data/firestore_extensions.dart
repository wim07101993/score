import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/user/models/roles.dart';

const _securityCollection = 'security';

extension UserFireStoreExtensions on FirebaseFirestore {
  Future<Roles> securityProperties(String userId) async {
    return collection(_securityCollection)
        .doc(userId)
        .get()
        .then((doc) => Roles.fromDocument(doc));
  }

  Stream<Roles> userPropertyChanges(String userId) {
    return collection(_securityCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => Roles.fromDocument(doc));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/user/data/security_properties.dart';

const _securityCollection = 'security';

extension UserFireStoreExtensions on FirebaseFirestore {
  Future<SecurityProperties> userProperties(String userId) async {
    return collection(_securityCollection)
        .doc(userId)
        .get()
        .then((doc) => SecurityProperties.fromDocument(doc));
  }

  Stream<SecurityProperties> userPropertyChanges(String userId) {
    return collection(_securityCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => SecurityProperties.fromDocument(doc));
  }
}

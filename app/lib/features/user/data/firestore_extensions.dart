import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/features/user/data/user_properties.dart';

const _securityCollection = 'security';

extension UserFireStoreExtensions on FirebaseFirestore {
  Future<UserProperties> userProperties(String userId) async {
    final doc = collection(_securityCollection).doc(userId);
    doc.set({'type': 'admin'});
    return collection(_securityCollection)
        .doc(userId)
        .get()
        .then((doc) => UserProperties.fromDocument(doc));
  }

  Stream<UserProperties> userPropertyChanges(String userId) {
    return collection(_securityCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => UserProperties.fromDocument(doc));
  }
}

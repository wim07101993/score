import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  guest,
  standard,
  contributor,
  admin,
}

UserType parseUserType(String? value) {
  switch (value) {
    case 'standard':
      return UserType.standard;
    case 'contributor':
      return UserType.contributor;
    case 'admin':
      return UserType.admin;
    default:
      return UserType.guest;
  }
}

class UserProperties {
  const UserProperties({
    required this.type,
  });

  const UserProperties.empty()
      : this(
          type: UserType.guest,
        );

  factory UserProperties.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      return const UserProperties.empty();
    }
    return UserProperties(
      type: parseUserType(doc['type'] as String?),
    );
  }

  final UserType type;
}

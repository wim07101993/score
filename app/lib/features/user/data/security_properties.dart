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

class SecurityProperties {
  const SecurityProperties({
    required this.type,
  });

  const SecurityProperties.empty() : this(type: UserType.guest);

  factory SecurityProperties.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      return const SecurityProperties.empty();
    }
    return SecurityProperties(
      type: parseUserType(doc['type'] as String?),
    );
  }

  final UserType type;
}

import 'package:score/features/user/data/user_properties.dart';

abstract class User {
  const User._({
    required this.id,
    required this.displayName,
  });

  factory User.fromFirebase({
    required String id,
    required String? displayName,
    required UserProperties userProperties,
  }) {
    switch (userProperties.type) {
      case UserType.guest:
        return Guest._(
          id: id,
          displayName: displayName,
        );
      case UserType.standard:
        return StandardUser._(
          id: id,
          displayName: displayName,
        );
      case UserType.contributor:
        return Contributor._(
          id: id,
          displayName: displayName,
        );
      case UserType.admin:
        return Admin._(
          id: id,
          displayName: displayName,
        );
    }
  }

  final String id;
  final String? displayName;

  T when<T>({
    required T Function(Guest user) guest,
    required T Function(StandardUser user) standardUser,
    required T Function(Contributor user) contributor,
    required T Function(Admin user) admin,
  });
}

class Guest extends User {
  Guest._({
    required String id,
    required String? displayName,
  }) : super._(
          id: id,
          displayName: displayName,
        );

  @override
  T when<T>({
    required T Function(Guest user) guest,
    required T Function(StandardUser user) standardUser,
    required T Function(Contributor user) contributor,
    required T Function(Admin user) admin,
  }) {
    return guest(this);
  }
}

class StandardUser extends User {
  StandardUser._({
    required String id,
    required String? displayName,
  }) : super._(
          id: id,
          displayName: displayName,
        );

  @override
  T when<T>({
    required T Function(Guest user) guest,
    required T Function(StandardUser user) standardUser,
    required T Function(Contributor user) contributor,
    required T Function(Admin user) admin,
  }) {
    return standardUser(this);
  }
}

class Contributor extends User {
  Contributor._({
    required String id,
    required String? displayName,
  }) : super._(
          id: id,
          displayName: displayName,
        );

  @override
  T when<T>({
    required T Function(Guest user) guest,
    required T Function(StandardUser user) standardUser,
    required T Function(Contributor user) contributor,
    required T Function(Admin user) admin,
  }) {
    return contributor(this);
  }
}

class Admin extends User {
  Admin._({
    required String id,
    required String? displayName,
  }) : super._(
          id: id,
          displayName: displayName,
        );

  @override
  T when<T>({
    required T Function(Guest user) guest,
    required T Function(StandardUser user) standardUser,
    required T Function(Contributor user) contributor,
    required T Function(Admin user) admin,
  }) {
    return admin(this);
  }
}

import 'package:equatable/equatable.dart';
import 'package:score/features/user/models/roles.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String email;
  final String? displayName;
  final Roles roles;

  @override
  List<Object?> get props => [id, email, displayName, roles];

  bool get hasReadAccess => roles.hasReadAccess;
}

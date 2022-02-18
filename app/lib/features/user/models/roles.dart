import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Roles extends Equatable {
  const Roles._({
    required this.hasReadAccess,
    required this.hasContributionAccess,
  });

  const Roles.empty()
      : this._(
          hasReadAccess: false,
          hasContributionAccess: false,
        );

  factory Roles.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      return const Roles.empty();
    }
    final roles = doc['roles'] as List?;
    if (roles == null) {
      return const Roles.empty();
    }
    return Roles._(
      hasReadAccess: roles.contains('reader'),
      hasContributionAccess: roles.contains('contributor'),
    );
  }

  final bool hasReadAccess;
  final bool hasContributionAccess;

  @override
  List<Object?> get props => [hasReadAccess, hasContributionAccess];
}

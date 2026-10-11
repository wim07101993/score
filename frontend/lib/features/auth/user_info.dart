import 'package:oidc/oidc.dart';

class const UserInfo({
  required final OidcUser oidcUser,
  required final String rolesKey,
}) {
  static const String scoreViewerRole = 'score_viewer';
  static const String scoreEditorRole = 'score_editor';

  String? get accessToken => oidcUser.token.accessToken;
  String? get id => oidcUser.claims.subject;
  String? get name => oidcUser.claims['name'] as String?;
  String? get email => oidcUser.claims['email'] as String?;

  Map<String, dynamic> get roles => switch (oidcUser.claims[rolesKey]) {
    final Map<String, dynamic> roles => roles,
    _ => const {},
  };

  bool get isScoreViewer => roles.containsKey(scoreViewerRole);
  bool get isScoreEditor => roles.containsKey(scoreEditorRole);
}

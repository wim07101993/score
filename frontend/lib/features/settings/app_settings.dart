class AppSettings {
  const AppSettings({
    required this.auth,
  });

  final AuthSettings auth;
}

class AuthSettings {
  const AuthSettings({
    required this.clientId,
    required this.discoveryDocumentUri,
    required this.loginRedirectUri,
    required this.postLogoutRedirectUri,
  });

  final String clientId;
  final Uri discoveryDocumentUri;
  final Uri loginRedirectUri;
  final Uri postLogoutRedirectUri;
}

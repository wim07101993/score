import 'package:oidc/oidc.dart';

class GoogleUserManager extends OidcUserManager {
  GoogleUserManager.lazy({
    required super.clientCredentials,
    required super.store,
    required super.settings,
  }) : super.lazy(
          discoveryDocumentUri: Uri.parse(
            'https://accounts.google.com/.well-known/openid-configuration',
          ),
        );
}

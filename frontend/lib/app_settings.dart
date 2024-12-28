import 'package:score/features/settings/app_settings.dart';

final appSettings = AppSettings(
  auth: AuthSettings(
    clientId: '299986611922337795',
    discoveryDocumentUri: Uri.parse(
      'http://localhost:7003/.well-known/openid-configuration',
    ),
    loginRedirectUri: Uri.parse('http://localhost:0/auth/login-callback'),
    postLogoutRedirectUri: Uri.parse('http://localhost:0/auth/logout-callback'),
  ),
);

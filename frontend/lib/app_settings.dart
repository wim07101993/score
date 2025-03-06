import 'package:score/features/settings/app_settings.dart';

final appSettings = AppSettings(
  scoreApi: const ScoreApiSettings(
    host: 'localhost',
    port: 8900,
  ),
  auth: AuthSettings(
    clientId: '309755485458857987',
    discoveryDocumentUri: Uri.parse(
      'http://localhost:7003/.well-known/openid-configuration',
    ),
    loginRedirectUri: Uri.parse('http://localhost:0/auth/login-callback'),
    postLogoutRedirectUri: Uri.parse('http://localhost:0/auth/logout-callback'),
  ),
);

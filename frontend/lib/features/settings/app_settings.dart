import 'package:grpc/grpc.dart';

class AppSettings {
  const AppSettings({
    required this.auth,
    required this.scoreApi,
  });

  final AuthSettings auth;
  final ScoreApiSettings scoreApi;
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

class ScoreApiSettings {
  const ScoreApiSettings({
    required this.host,
    required this.port,
    this.channelOptions = const ChannelOptions(),
  });

  final String host;
  final int port;
  final ChannelOptions channelOptions;
}

import 'dart:async';
import 'dart:convert';

import 'package:oidc/oidc.dart';

String testIdToken(Map<String, Object?> claims) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.';
}

Future<OidcUser> testOidcUser({
  Map<String, Object?> claims = const {'sub': 'player'},
  String accessToken = 'a-token',
}) => OidcUser.fromIdToken(
  token: OidcToken(
    creationTime: DateTime.now(),
    idToken: testIdToken(claims),
    accessToken: accessToken,
    expiresIn: const Duration(hours: 1),
  ),
);

class TestOidcUserManager extends OidcUserManager {
  TestOidcUserManager({this.user})
    : super(
        discoveryDocument: OidcProviderMetadata.fromJson({
          'issuer': 'https://auth.invalid',
          'authorization_endpoint': 'https://auth.invalid/authorize',
          'token_endpoint': 'https://auth.invalid/token',
          'response_types_supported': ['code'],
        }),
        clientCredentials: const OidcClientAuthentication.none(
          clientId: 'test',
        ),
        store: OidcMemoryStore(),
        settings: OidcUserManagerSettings(
          redirectUri: Uri.parse('http://localhost:3000/redirect.html'),
        ),
      );

  OidcUser? user;
  final _changes = StreamController<OidcUser?>.broadcast();

  Object? accessTokenFailure;
  Object? signInFailure;
  OidcUser? signsInAs;
  int signIns = 0;
  int forcedRefreshes = 0;

  void changeTo(OidcUser? user) {
    this.user = user;
    _changes.add(user);
  }

  @override
  Future<void> init() async {}

  @override
  OidcUser? get currentUser => user;

  @override
  Stream<OidcUser?> userChanges() => Stream.multi((controller) {
    controller.add(user);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<String?> getAccessToken({
    Duration minValidity = const Duration(seconds: 30),
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) forcedRefreshes++;
    if (accessTokenFailure case final failure?) throw failure;
    return user?.token.accessToken;
  }

  @override
  Future<OidcUser?> loginAuthorizationCodeFlow({
    OidcProviderMetadata? discoveryDocumentOverride,
    Uri? redirectUriOverride,
    Uri? originalUri,
    List<String>? scopeOverride,
    List<String>? promptOverride,
    List<String>? uiLocalesOverride,
    String? displayOverride,
    List<String>? acrValuesOverride,
    dynamic extraStateData,
    bool includeIdTokenHintFromCurrentUser = true,
    String? idTokenHintOverride,
    String? loginHint,
    Duration? maxAgeOverride,
    Map<String, dynamic>? extraParameters,
    Map<String, dynamic>? extraTokenParameters,
    Map<String, String>? extraTokenHeaders,
    OidcPlatformSpecificOptions? options,
    List<String>? responseTypeOverride,
  }) async {
    signIns++;
    if (signInFailure case final failure?) throw failure;
    if (signsInAs case final signedIn?) changeTo(signedIn);
    return signsInAs;
  }
}

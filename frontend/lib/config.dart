import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('Config');

/// What the app has to be told before it can do anything: where the API is, and
/// how a user proves who they are.
///
/// It is read at start-up rather than compiled in, so that the same build can
/// be pointed at a development server and at a real one. On the web it is
/// fetched as a file next to the app, which is what lets it be changed without
/// building anything.
class Config {
  const Config({
    required this.oidc,
    required this.api,
  });

  factory Config.fromJson(
    Map<String, dynamic> json,
  ) => Config(
        oidc: OidcConfig.fromJson(json['oidc'] as Map<String, dynamic>),
        api: ApiConfig.fromJson(json['api'] as Map<String, dynamic>),
      );

  final OidcConfig oidc;
  final ApiConfig api;

  static Future<Config> load([String asset = 'assets/config.json']) async {
    final text = await rootBundle.loadString(asset);
    return Config.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}

class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
  });

  factory ApiConfig.fromJson(
    Map<String, dynamic> json,
  ) =>
      ApiConfig(baseUrl: _uri(json['baseUrl']));

  final Uri baseUrl;

  /// The address of one of the API's paths. The base is written with a trailing
  /// slash or without one depending on who wrote the file, so it is not trusted
  /// to have one.
  Uri path(String path, [Map<String, String>? query]) {
    final base = baseUrl.toString();
    final joined = base.endsWith('/') ? '$base$path' : '$base/$path';
    final uri = Uri.parse(joined);
    return query == null ? uri : uri.replace(queryParameters: query);
  }
}

class OidcConfig {
  const OidcConfig({
    required this.clientId,
    String? nativeClientId,
    required this.issuer,
    required this.redirectUri,
    required this.nativeRedirectUri,
    required this.desktopRedirectUri,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userInfoEndpoint,
    required this.healthzEndpoint,
    required this.rolesKey,
  }) : nativeClientId = nativeClientId ?? clientId;

  factory OidcConfig.fromJson(
    Map<String, dynamic> json,
  ) {
    final nativeClientId = json['nativeClientId'] == null
        ? null
        : '${json['nativeClientId']}';
    final hasNativeClient = nativeClientId != null && nativeClientId.isNotEmpty;
    if (!kIsWeb && !hasNativeClient) {
      // Kept as a fallback, because one client can be enough: a provider other
      // than Zitadel, or a web client that was given the device's redirect
      // addresses as well. When it is not, the sign-in fails at the provider
      // with a redirect_uri mismatch and nothing on the device says why, so it
      // is said here. A release does not even build without one (see
      // .github/workflows/release.yaml).
      _log.warning('the config has no nativeClientId, so this device signs in as '
          'the web client ${json['clientId']}; the provider will refuse that '
          'unless the redirect addresses of a device are registered on it too');
    }
    return OidcConfig(
      clientId: '${json['clientId']}',
      nativeClientId: hasNativeClient ? nativeClientId : null,
      issuer: json['issuer'] == null
          // Not stated, so taken to be wherever the endpoints are. Every
          // provider worth the name serves its metadata at the root of the
          // same host, and a wrong guess here costs nothing: discovery that
          // fails falls back to the endpoints written out below.
          ? Uri.parse(_uri(json['authorizationEndpoint']).origin)
          : _uri(json['issuer']),
      redirectUri: _uri(json['redirectUri']),
      nativeRedirectUri: json['nativeRedirectUri'] == null
          ? Uri.parse('app.wvl.score://callback')
          : _uri(json['nativeRedirectUri']),
      desktopRedirectUri: json['desktopRedirectUri'] == null
          ? Uri.parse('http://localhost:7005/')
          : _uri(json['desktopRedirectUri']),
      authorizationEndpoint: _uri(json['authorizationEndpoint']),
      tokenEndpoint: _uri(json['tokenEndpoint']),
      userInfoEndpoint: _uri(json['userInfoEndpoint']),
      healthzEndpoint: _uri(json['healthzEndpoint']),
      rolesKey: '${json['rolesKey']}',
    );
  }

  /// The client the web app signs in as.
  final String clientId;

  /// The client a phone or a desktop signs in as, and the same as [clientId]
  /// when none is given — which [OidcConfig.fromJson] warns about on a device.
  ///
  /// A provider may well refuse the web's client for them: it is a client
  /// whose redirect addresses are web pages, where a phone comes back to a
  /// scheme of its own and a desktop to a port on localhost (see
  /// [nativeRedirectUri] and [desktopRedirectUri]). Zitadel wants a native
  /// application for that, with those addresses registered on it.
  final String nativeClientId;

  /// The client this build signs in as.
  String get clientIdHere => kIsWeb ? clientId : nativeClientId;

  /// Where the provider describes itself.
  ///
  /// Asking it — `/.well-known/openid-configuration` — is how the endpoints
  /// below are learned rather than assumed, and how anything the provider moves
  /// is followed without this app being rebuilt. What is written below is what
  /// is used when it cannot be asked, which on a device with no network is the
  /// ordinary case rather than an error.
  final Uri issuer;

  /// Where the provider sends a browser back to. On the web this is the app
  /// itself, so the page that comes back is the page that asked.
  final Uri redirectUri;

  /// Where it sends a phone back to, which cannot be a page: an app is not
  /// reached by a web address. It is a scheme the operating system knows
  /// belongs to this app, and it has to be registered with the provider
  /// alongside the other one.
  final Uri nativeRedirectUri;

  /// Where it sends a desktop back to.
  ///
  /// A third one, because a desktop has no such thing as an app that owns a
  /// scheme. What it has instead is a port: the app listens on one for as long
  /// as the sign-in takes, the browser is sent back to it, and it hears the
  /// answer that way. It has to be registered with the provider like the
  /// others, port and all.
  final Uri desktopRedirectUri;

  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri userInfoEndpoint;

  /// Somewhere to ask whether the provider is there at all, which is how the
  /// app tells "you are signed out" from "there is no network".
  final Uri healthzEndpoint;

  /// The claim the roles of a user are read out of. Which one that is, is the
  /// provider's business — Zitadel puts them under a urn.
  final String rolesKey;
}

Uri _uri(Object? value) => Uri.parse('$value');

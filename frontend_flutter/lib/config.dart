import 'dart:convert';

import 'package:flutter/services.dart';

/// What the app has to be told before it can do anything: where the API is, and
/// how a user proves who they are.
///
/// It is read at start-up rather than compiled in, so that the same build can
/// be pointed at a development server and at a real one. On the web it is
/// fetched as a file next to the app, which is what lets it be changed without
/// building anything.
class Config {
  const Config({required this.oidc, required this.api});

  final OidcConfig oidc;
  final ApiConfig api;

  static Future<Config> load([String asset = 'assets/config.json']) async {
    final text = await rootBundle.loadString(asset);
    return Config.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        oidc: OidcConfig.fromJson(json['oidc'] as Map<String, dynamic>),
        api: ApiConfig.fromJson(json['api'] as Map<String, dynamic>),
      );
}

class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final Uri baseUrl;

  factory ApiConfig.fromJson(Map<String, dynamic> json) =>
      ApiConfig(baseUrl: _uri(json['baseUrl']));

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
    required this.redirectUri,
    required this.nativeRedirectUri,
    required this.desktopRedirectUri,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userInfoEndpoint,
    required this.healthzEndpoint,
    required this.rolesKey,
  });

  final String clientId;

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

  factory OidcConfig.fromJson(Map<String, dynamic> json) => OidcConfig(
        clientId: '${json['clientId']}',
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

Uri _uri(Object? value) => Uri.parse('$value');

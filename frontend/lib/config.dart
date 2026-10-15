import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/helpers/json_map_extensions.dart';

class const Config({
  required final OidcConfig oidc,
  required final ApiConfig api,
}) {
  factory Config.fromJson(Map json) {
    return Config(
      oidc:
          json.getObject('oidc', OidcConfig.fromJson) ??
          (throw const ConfigInvalidException('no oidc specified')),
      api:
          json.getObject('api', ApiConfig.fromJson) ??
          (throw const ConfigInvalidException('no api specified')),
    );
  }

  static Future<Config> load({
    String asset = 'assets/config.json',
  }) async {
    final text = await rootBundle.loadString(asset);
    return Config.fromJson(jsonDecode(text) as Map);
  }
}

class const ConfigInvalidException(final String message) implements Exception {}

class const ApiConfig({
  required final Uri baseUrl,
}) {
  factory ApiConfig.fromJson(Map json) {
    return ApiConfig(
      baseUrl:
          json.get('baseUrl', parser: Uri.parse) ??
          (throw const ApiConfigInvalidException('no baseUrl specified')),
    );
  }

  Uri path(String path, [Map<String, String>? query]) {
    final base = baseUrl.toString();
    final joined = base.endsWith('/') ? '$base$path' : '$base/$path';
    final uri = Uri.parse(joined);
    return query == null ? uri : uri.replace(queryParameters: query);
  }
}

class const ApiConfigInvalidException(final String message)
    implements Exception {}

class OidcConfig {
  OidcConfig({
    required this.discoveryEndpoint,
    required this.healthzEndpoint,
    required this.rolesKey,
    required this.client,
    required this.webClient,
    required this.mobileClient,
    required this.desktopClient,
    required List<String> scopes,
  }) : scopes = <String>{
         'openid',
         'email',
         'profile',
         'offline_access',
         ...scopes,
       }.toList(growable: false) {
    if (client == null &&
        (webClient == null || mobileClient == null || desktopClient == null)) {
      throw const OidcConfigInvalidException(
        'Not default oidc-client-config was specified. When either web, '
        'mobile or desktop client is specified, a "client" must be '
        'specified which is used as default.',
      );
    }
    if (rolesKey.isEmpty) {
      throw const OidcConfigInvalidException(
        'No rolesKey specified. This key is used to take the roles from an '
        'issued token. These roles are used to determine whether a user can '
        'read/write scores. The roles are: ${UserInfo.scoreViewerRole} and '
        '${UserInfo.scoreEditorRole}',
      );
    }
  }

  final Uri discoveryEndpoint;
  final Uri healthzEndpoint;
  final String rolesKey;
  final OidcClientConfig? client;
  final OidcClientConfig? webClient;
  final OidcClientConfig? mobileClient;
  final OidcClientConfig? desktopClient;
  final List<String> scopes;

  factory OidcConfig.fromJson(Map json) {
    return OidcConfig(
      discoveryEndpoint:
          json.get('discoveryEndpoint', parser: Uri.parse) ??
          (throw const OidcConfigInvalidException(
            'no discoveryEndpoint specified',
          )),
      healthzEndpoint:
          json.get('healthzEndpoint', parser: Uri.parse) ??
          (throw const OidcConfigInvalidException(
            'no healthzEndpoint specified',
          )),
      rolesKey: json.get('rolesKey') ?? '',
      client: json.getObject(
        'client',
        (map) => OidcClientConfig.fromJson(json: map),
      ),
      webClient: json.getObject(
        'webClient',
        (map) => OidcClientConfig.fromJson(json: map),
      ),
      mobileClient: json.getObject(
        'mobileClient',
        (map) => OidcClientConfig.fromJson(
          json: map,
          defaultRedirectUri: Uri.parse('app.wvl.score://callback'),
        ),
      ),
      desktopClient: json.getObject(
        'desktopClient',
        (map) => OidcClientConfig.fromJson(
          json: map,
          defaultRedirectUri: Uri.parse('http://localhost:7005'),
        ),
      ),
      scopes: json.getList('scopes'),
    );
  }

  OidcClientConfig get clientConfig {
    if (kIsWeb) {
      return webClient ?? client!;
    }
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return desktopClient ?? client!;
    }
    return mobileClient ?? client!;
  }
}

class const OidcConfigInvalidException(final String message)
    implements Exception {}

class OidcClientConfig {
  OidcClientConfig({
    required this.clientId,
    required this.redirectUri,
  }) {
    if (clientId.isEmpty) {
      throw const OidcClientConfigInvalidException('No clientId specified');
    }
  }

  final String clientId;
  final Uri redirectUri;

  factory fromJson({
    required Map json,
    Uri? defaultRedirectUri,
  }) {
    return OidcClientConfig(
      clientId: json.get('clientId') ?? '',
      redirectUri:
          json.get<Uri>('redirectUri', parser: Uri.parse) ??
          defaultRedirectUri ??
          (throw const OidcClientConfigInvalidException(
            'No redirectUri specified',
          )),
    );
  }
}

class const OidcClientConfigInvalidException(final String message)
    implements Exception {}

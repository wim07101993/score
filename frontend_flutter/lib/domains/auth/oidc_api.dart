import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../data/local_store.dart';
import 'authorizer.dart';

/// Proving who the user is, and finding out what they may do.
///
/// The flow is an authorization code with PKCE, which is the one a client that
/// cannot keep a secret is allowed to use — and a browser, a phone and a laptop
/// are all clients that cannot keep a secret. What the app gets out of it is an
/// access token to call the API with and a set of roles to decide what to show.
///
/// Where this differs from the app it replaces: the tokens are kept where they
/// survive a restart rather than only for as long as a tab is open. A device
/// that is closed and opened again at the next rehearsal should not ask the
/// player to sign in again, and a refresh token that lives no longer than a tab
/// is a refresh token that never gets used. Signing out throws them away, which
/// is what the profile page is for.
const List<String> _scopes = ['openid', 'email', 'profile', 'offline_access'];

const _tokenKey = 'auth_token_response';
const _refreshTokenKey = 'auth_refresh_token';
const _flowStateKey = 'auth_flow_state';
const _userInfoKey = 'app_user_info';

class OidcApi {
  OidcApi(this._config, this._store, {http.Client? client, Authorizer? authorizer})
      : _client = client ?? http.Client(),
        _authorizer = authorizer ?? Authorizer(_config);

  final OidcConfig _config;
  final LocalStore _store;
  final http.Client _client;
  final Authorizer _authorizer;

  /// A token that is good right now, asking for a new one when there is not
  /// one. `null` when the user has to sign in and the app is about to send them
  /// away to do it.
  Future<String?> getActiveAccessToken() async {
    final held = await _heldToken();
    if (held != null) {
      return held;
    }
    return getFreshAccessToken();
  }

  Future<String?> _heldToken() async {
    final json = await _store.readSetting(_tokenKey);
    if (json == null) {
      return null;
    }

    final token = jsonDecode(json) as Map<String, dynamic>;
    final expiresAt = token['expires_at'];
    if (expiresAt is int &&
        DateTime.now().millisecondsSinceEpoch >
            expiresAt - const Duration(seconds: 30).inMilliseconds) {
      // Half a minute of slack, so that a token is never spent on a request
      // that will take longer to arrive than the token has left.
      return null;
    }
    final access = token['access_token'];
    return access is String && access.isNotEmpty ? access : null;
  }

  /// Gets a token by whatever means are left: the code the user just came back
  /// with, the refresh token this device is holding, or by asking them.
  Future<String?> getFreshAccessToken() async {
    final callback = await _authorizer.pendingCallback();
    if (callback != null) {
      final token = await _exchangeCallback(callback);
      await _authorizer.clearCallback();
      if (token != null) {
        return token;
      }
    }

    final refreshToken = await _store.readSetting(_refreshTokenKey);
    if (refreshToken != null) {
      final token = await _refresh(refreshToken);
      if (token != null) {
        return token;
      }
    }

    return _startFlow();
  }

  /// Turns the code the user came back with into a token. `null` when there was
  /// nothing to turn, or when the provider refused it.
  Future<String?> _exchangeCallback(Callback callback) async {
    final flow = await _readFlowState();
    if (flow == null || flow.state != callback.state) {
      // A code that came back with a state this device never sent is a code
      // this device did not ask for.
      return null;
    }

    try {
      final token = await _callTokenEndpoint({
        'client_id': _config.clientId,
        'grant_type': 'authorization_code',
        'redirect_uri': _authorizer.redirectUri.toString(),
        'code': callback.code,
        'code_verifier': flow.verifier,
      });
      await _keep(token);
      return token['access_token'] as String?;
    } catch (error) {
      await _forgetTokens();
      return null;
    } finally {
      await _store.writeSetting(_flowStateKey, null);
    }
  }

  Future<String?> _refresh(String refreshToken) async {
    try {
      final token = await _callTokenEndpoint({
        'client_id': _config.clientId,
        'grant_type': 'refresh_token',
        'redirect_uri': _authorizer.redirectUri.toString(),
        'scope': _scopes.join(' '),
        'refresh_token': refreshToken,
      });
      await _keep(token);
      return token['access_token'] as String?;
    } catch (error) {
      await _forgetTokens();
      return null;
    }
  }

  /// Sends the user to the provider. On a device the answer comes back here; on
  /// the web the app is on its way out and the answer will be waiting when it
  /// starts again.
  Future<String?> _startFlow() async {
    final flow = _FlowState.create();
    await _store.writeSetting(_flowStateKey, jsonEncode(flow.toJson()));

    final url = _config.authorizationEndpoint.replace(queryParameters: {
      'client_id': _config.clientId,
      'redirect_uri': _authorizer.redirectUri.toString(),
      'scope': _scopes.join(' '),
      'response_type': 'code',
      'code_challenge': flow.challenge,
      'code_challenge_method': 'S256',
      'state': flow.state,
    });

    final callback = await _authorizer.authorize(url);
    if (callback == null) {
      return null;
    }
    return _exchangeCallback(callback);
  }

  Future<Map<String, dynamic>> _callTokenEndpoint(
      Map<String, String> body) async {
    final response = await _client.post(
      _config.tokenEndpoint,
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode >= 400) {
      throw OidcException(
        'failed to get an access token: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Keeps what the provider sent, with the moment it runs out worked out now:
  /// what it says is how long the token lasts, and how long is only an answer
  /// while it is being read.
  Future<void> _keep(Map<String, dynamic> token) async {
    final expiresIn = token['expires_in'];
    token['expires_at'] = DateTime.now()
        .add(Duration(seconds: expiresIn is int ? expiresIn : 300))
        .millisecondsSinceEpoch;

    await _store.writeSetting(_tokenKey, jsonEncode(token));

    final refresh = token['refresh_token'];
    if (refresh is String && refresh.isNotEmpty) {
      await _store.writeSetting(_refreshTokenKey, refresh);
    }
  }

  Future<void> _forgetTokens() async {
    await _store.writeSetting(_tokenKey, null);
    await _store.writeSetting(_refreshTokenKey, null);
  }

  Future<_FlowState?> _readFlowState() async {
    final json = await _store.readSetting(_flowStateKey);
    if (json == null) {
      return null;
    }
    return _FlowState.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// What the provider says about the user right now.
  Future<UserInfo?> getUserInfo() async {
    final token = await getActiveAccessToken();
    if (token == null) {
      return null;
    }

    final response = await _client.get(
      _config.userInfoEndpoint,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      throw OidcException(
        'failed to get the user info: ${response.statusCode} ${response.body}',
      );
    }

    final claims = jsonDecode(response.body) as Map<String, dynamic>;
    final user = UserInfo.fromClaims(claims, _config.rolesKey);
    await _store.writeSetting(_userInfoKey, jsonEncode(user.toJson()));
    return user;
  }

  /// What the provider last said about the user, from before there was no
  /// network to ask over.
  Future<UserInfo?> keptUserInfo() async {
    final json = await _store.readSetting(_userInfoKey);
    if (json == null) {
      return null;
    }
    return UserInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Whether the provider is there to be asked.
  ///
  /// A provider that cannot be reached is answered `false` rather than thrown
  /// about: this is asked to find out whether to work from what is kept on the
  /// device, and a network that is down is the very case it is asked in.
  Future<bool> canBeReached() async {
    try {
      final response = await _client
          .get(_config.healthzEndpoint)
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (error) {
      return false;
    }
  }

  /// Forgets who is signed in on this device.
  ///
  /// It signs nobody out at the provider — that is the provider's own business,
  /// and this app is in no position to speak for it. What it does is make the
  /// next visit ask again from the beginning, which is the way out of a token
  /// or a set of roles that has gone stale.
  ///
  /// The scores and sets on this device are left alone: they are what makes the
  /// app work without a network, and they are no use to anyone who cannot get a
  /// token to read them with anyway.
  Future<void> forgetUser() async {
    await _forgetTokens();
    await _store.writeSetting(_flowStateKey, null);
    await _store.writeSetting(_userInfoKey, null);
  }
}

class OidcException implements Exception {
  OidcException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// THE FLOW
// ---------------------------------------------------------------------------

/// What this device has to remember while the user is away at the provider: the
/// secret it will prove the code with, and a nonce to recognise its own answer
/// by.
class _FlowState {
  _FlowState(this.state, this.verifier, this.challenge);

  final String state;
  final String verifier;
  final String challenge;

  static _FlowState create() {
    final verifier = _randomString(56);
    return _FlowState(_randomString(16), verifier, _challengeFor(verifier));
  }

  Map<String, dynamic> toJson() =>
      {'state': state, 'verifier': verifier, 'challenge': challenge};

  factory _FlowState.fromJson(Map<String, dynamic> json) => _FlowState(
        '${json['state']}',
        '${json['verifier']}',
        '${json['challenge']}',
      );
}

const _alphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

String _randomString(int length) {
  final random = Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < length; i++)
      _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
  ]);
}

/// The verifier as the provider will check it: hashed, and written the way a
/// url can carry it.
String _challengeFor(String verifier) => base64Url
    .encode(sha256.convert(utf8.encode(verifier)).bytes)
    .replaceAll('=', '');

// ---------------------------------------------------------------------------
// THE USER
// ---------------------------------------------------------------------------

/// What the provider said about the user, and what this app made of it.
///
/// The claims it was read out of are kept alongside it. What a provider answers
/// with is the one thing that explains why this app thinks what it thinks about
/// a user — which is worth being able to show when it thinks something the user
/// disagrees with.
class UserInfo {
  const UserInfo({
    this.name,
    this.subject,
    this.email,
    this.roles,
    this.claims,
    this.rolesKey,
  });

  final String? name;
  final String? subject;
  final String? email;

  /// The roles as the provider sent them, which is a map whose keys are the
  /// role names.
  final Map<String, dynamic>? roles;

  /// The answer this was read out of.
  final Map<String, dynamic>? claims;

  /// The claim the roles were looked for under.
  final String? rolesKey;

  bool get isScoreEditor => roles?['score_editor'] != null;

  bool get isScoreViewer => roles?['score_viewer'] != null;

  factory UserInfo.fromClaims(Map<String, dynamic> claims, String rolesKey) {
    final roles = claims[rolesKey];
    return UserInfo(
      name: claims['name'] as String?,
      subject: claims['sub'] as String?,
      email: claims['email'] as String?,
      roles: roles is Map<String, dynamic> ? roles : null,
      claims: claims,
      rolesKey: rolesKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'subject': subject,
        'email': email,
        'roles': roles,
        'claims': claims,
        'rolesKey': rolesKey,
      };

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        name: json['name'] as String?,
        subject: json['subject'] as String?,
        email: json['email'] as String?,
        roles: (json['roles'] as Map?)?.cast<String, dynamic>(),
        claims: (json['claims'] as Map?)?.cast<String, dynamic>(),
        rolesKey: json['rolesKey'] as String?,
      );
}

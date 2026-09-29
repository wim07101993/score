import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart' as openid;
import 'package:score/config.dart';
import 'package:score/features/auth/authorizer.dart';
import 'package:score/features/sembast/local_store.dart';

/// Proving who the user is, and finding out what they may do.
///
/// The flow is an authorization code with PKCE, which is the one a client that
/// cannot keep a secret is allowed to use — and a browser, a phone and a laptop
/// are all clients that cannot keep a secret. What the app gets out of it is an
/// access token to call the API with and a set of roles to decide what to show.
///
/// The protocol is `openid_client`'s: discovery, the code exchange, the
/// refresh, the userinfo call. What is *not* its is getting the user to the
/// provider and back — see [Authorizer]. That package has transports of its own
/// for both, and they are the same shape as the ones here, but they are not
/// wired to this app's two awkward cases: a desktop that must not have its
/// sign-in cancelled the moment the window takes focus back, and a web app that
/// refuses to start a flow it can see will not come back. Those are kept.
///
/// The tokens are kept where they survive a restart rather than only for as
/// long as a tab is open. A device that is closed and opened again at the next
/// rehearsal should not ask the player to sign in again, and a refresh token
/// that lives no longer than a tab is a refresh token that never gets used.
/// Signing out throws them away, which is what the profile page is for.
const List<String> _scopes = ['openid', 'email', 'profile', 'offline_access'];

const _tokenKey = 'auth_token_response';
const _flowStateKey = 'auth_flow_state';
const _userInfoKey = 'app_user_info';

/// How much of a token's life to leave unspent.
///
/// A token handed to a request that takes longer to arrive than the token has
/// left is a token that arrives expired, and the request fails for a reason
/// nothing on either end can see. So one this close to the end is treated as
/// already gone.
const Duration _slack = Duration(seconds: 30);

class OidcApi {
  OidcApi(
    this._config,
    this._store, {
    http.Client? client,
    Authorizer? authorizer,
  })  : _http = client ?? http.Client(),
        _authorizer = authorizer ?? Authorizer(_config);

  final OidcConfig _config;
  final LocalStore _store;
  final http.Client _http;
  final Authorizer _authorizer;

  Future<openid.Client>? _clientFuture;

  /// The provider, as this app talks to it.
  ///
  /// Worked out once and held: discovery is a request, and every call that
  /// wants a token would otherwise make it again.
  Future<openid.Client> _client() =>
      _clientFuture ??= _describeProvider().then(
        (issuer) => openid.Client(issuer, _config.clientId, httpClient: _http),
      );

  /// What the provider says about itself, or what the config says when it
  /// cannot be asked.
  ///
  /// Asking is better: it follows anything the provider moves, and it is where
  /// the list of scopes it will actually grant comes from. But a device opening
  /// the app on a train has no way to ask, and a sign-in is not the only thing
  /// that needs a token — so a provider that cannot be reached falls back to
  /// the endpoints the config was built with rather than failing.
  Future<openid.Issuer> _describeProvider() async {
    try {
      return await openid.Issuer.discover(_config.issuer, httpClient: _http);
    } catch (_) {
      return openid.Issuer(openid.OpenIdProviderMetadata.fromJson({
        'issuer': _config.issuer.toString(),
        'authorization_endpoint': _config.authorizationEndpoint.toString(),
        'token_endpoint': _config.tokenEndpoint.toString(),
        'userinfo_endpoint': _config.userInfoEndpoint.toString(),
        'response_types_supported': ['code'],
        // Not decoration. A flow keeps only the scopes the provider is known to
        // support, so a metadata document that lists none asks for none — and
        // an authorization request with no `openid` scope is not a sign-in at
        // all. See [_flow].
        'scopes_supported': _scopes,
      }));
    }
  }

  /// Why the last sign-in did not finish, until one does or the user asks to
  /// try again.
  ///
  /// While there is one, nothing starts a sign-in on its own. On the web a
  /// sign-in is a redirect, and a callback that failed would otherwise send the
  /// browser straight back to the provider — which sends it straight back here
  /// to fail the same way, for as long as the tab is open, with nothing on
  /// screen long enough to read. So it stops, says why, and waits for the user.
  Object? get signInFailure => _signInFailure;
  Object? _signInFailure;

  /// Lets the next token asked for start a sign-in again. For the user asking
  /// to try again, and nothing else.
  void forgetSignInFailure() => _signInFailure = null;

  /// The one refresh in flight, shared by everyone who wants it.
  ///
  /// A provider that rotates refresh tokens takes each one exactly once. Two
  /// syncs refreshing at the same moment would both spend the same token, and
  /// the second would be refused — and forget the fresh one the first had just
  /// written down.
  Future<String?>? _refreshing;

  /// The one sign-in in flight, shared for the same reason: two would open two
  /// browsers, or on a desktop try to listen on the same port twice.
  Future<String?>? _signingIn;

  /// The code the app was started with being exchanged, shared so that it is
  /// spent once. A second exchange of the same code is refused.
  Future<String?>? _finishing;

  /// A token that is good right now, asking for a new one when there is not
  /// one. `null` when the user has to sign in and the app is about to send them
  /// away to do it, or when signing in failed — see [signInFailure].
  ///
  /// Throws when a refresh could not be done for a reason that says nothing
  /// about the refresh token, like a network that went away halfway through:
  /// the token is kept for the next try, and the caller hears about it.
  Future<String?> getActiveAccessToken() async {
    final held = await _heldToken();
    if (held != null) {
      return held;
    }
    return await getFreshAccessToken();
  }

  /// The token this device is holding, refreshed on the spot if it has run out
  /// and there is a refresh token to do it with.
  Future<String?> _heldToken() async {
    final credential = await _heldCredential();
    if (credential == null) {
      return null;
    }
    if (!_isSpent(credential)) {
      return credential.response?['access_token'] as String?;
    }
    return await _refresh();
  }

  /// Gets a token by whatever means are left: the code the user just came back
  /// with, the refresh token this device is holding, or by asking them.
  Future<String?> getFreshAccessToken() async {
    final finished = await (_finishing ??=
        _finishPendingSignIn().whenComplete(() => _finishing = null));
    if (finished != null) {
      return finished;
    }

    final refreshed = await _refresh();
    if (refreshed != null) {
      return refreshed;
    }

    if (_signInFailure != null) {
      return null;
    }
    return await (_signingIn ??=
        _startFlow().whenComplete(() => _signingIn = null));
  }

  /// Exchanges the code the app was started with, if it was. `null` when it
  /// was not, or when the exchange failed — which is kept in [signInFailure],
  /// so that the app does not go straight back to the provider to fail again.
  Future<String?> _finishPendingSignIn() async {
    final Callback? callback;
    try {
      callback = await _authorizer.pendingCallback();
    } catch (error) {
      // The provider sent the user back with a refusal rather than a code.
      await _authorizer.clearCallback();
      await _store.writeSetting(_flowStateKey, null);
      _signInFailure = error;
      return null;
    }
    if (callback == null) {
      return null;
    }

    // Read before the exchange, which throws the flow away once it is done.
    final started = await _readFlowState();
    final String token;
    try {
      token = await _exchangeCallback(callback);
    } catch (error) {
      _signInFailure = error;
      return null;
    } finally {
      await _authorizer.clearCallback();
    }
    await _authorizer.returnTo(started?.returnTo);
    return token;
  }

  /// Whether the token in [credential] is gone, or too close to it to spend.
  static bool _isSpent(openid.Credential credential) {
    final response = credential.response;
    if (response == null || response['access_token'] == null) {
      return true;
    }
    final expiresAt = _expiryOf(response);
    return expiresAt != null &&
        !expiresAt.subtract(_slack).isAfter(DateTime.now());
  }

  /// Refreshes the token this device is holding, joining a refresh already on
  /// its way rather than starting a second. `null` when there is no refresh
  /// token, or the provider refused the one there was.
  Future<String?> _refresh() =>
      _refreshing ??= _refreshNow().whenComplete(() => _refreshing = null);

  /// Keeps whatever came back: a provider that rotates refresh tokens hands a
  /// new one out with every refresh, and a device that did not write it down
  /// cannot refresh twice.
  ///
  /// The refresh token is only forgotten when the provider says it is no good.
  /// A refresh that failed because the network did is the same refresh token
  /// working fine the next time there is one, and throwing it away would make
  /// a player sign in again over a dropped connection.
  Future<String?> _refreshNow() async {
    // Read again rather than handed in: a refresh that finished a moment ago
    // may have written down a newer one, and the old one is already spent.
    final credential = await _heldCredential();
    if (credential == null) {
      return null;
    }
    if (!_isSpent(credential)) {
      return credential.response!['access_token'] as String?;
    }
    if (credential.refreshToken == null) {
      return null;
    }

    try {
      final response = await credential.getTokenResponse(true);
      await _keep(credential);
      return response.accessToken;
    } catch (error) {
      if (!_refused(error)) {
        rethrow;
      }
      await _forgetTokens();
      return null;
    }
  }

  /// Whether [error] is the token endpoint saying the refresh token is no good,
  /// as opposed to not having been reached, or having had a bad moment.
  static bool _refused(Object error) => switch (error) {
        openid.OpenIdException(:final code) => code == 'invalid_grant',
        openid.HttpRequestException(:final statusCode) =>
          statusCode == 400 || statusCode == 401,
        _ => false,
      };

  /// Turns the code the user came back with into a token. Throws when there was
  /// no sign-in started here for it to belong to, or when the provider refused
  /// it.
  Future<String> _exchangeCallback(Callback callback) async {
    final held = await _readFlowState();
    if (held == null) {
      // Nothing was sent from this device, so nothing can have come back to it.
      throw OidcException(
        'a sign-in came back that was not started on this device',
      );
    }

    try {
      // The same flow the user was sent away on, built again: the verifier it
      // will prove the code with is the one whose challenge went out, and on
      // the web that was in a previous life of this app. `openid_client` checks
      // the state itself and refuses a mismatch.
      final flow = await _flow(held);
      final credential = await flow.callback({
        'code': callback.code,
        'state': callback.state,
      });
      await _keep(credential);
      final token = (await credential.getTokenResponse()).accessToken;
      if (token == null) {
        throw OidcException('the provider sent no access token');
      }
      _signInFailure = null;
      return token;
    } finally {
      await _store.writeSetting(_flowStateKey, null);
    }
  }

  /// Sends the user to the provider. On a device the answer comes back here; on
  /// the web the app is on its way out and the answer will be waiting when it
  /// starts again.
  Future<String?> _startFlow() async {
    final started = _FlowState(
      _randomString(24),
      _randomString(56),
      returnTo: _authorizer.whereTheUserIs(),
    );
    final flow = await _flow(started);

    // Written down before the user goes anywhere. On the web this app is about
    // to stop existing, and what comes back is worthless without these — and
    // the user is lost without the last one.
    await _store.writeSetting(
      _flowStateKey,
      jsonEncode({
        'state': started.state,
        'verifier': started.verifier,
        'return_to': started.returnTo?.toString(),
      }),
    );

    try {
      final callback = await _authorizer.authorize(flow.authenticationUri);
      if (callback == null) {
        return null;
      }
      return await _exchangeCallback(callback);
    } catch (error) {
      // Kept, so that the next sync does not open another browser to fail in.
      _signInFailure = error;
      return null;
    }
  }

  /// The authorization-code flow, built on [started].
  ///
  /// The same two values build the flow that goes out and the flow that reads
  /// the answer — which on the web are in two different lives of this app, and
  /// is the whole reason they are written down rather than kept in memory.
  Future<openid.Flow> _flow(_FlowState started) async {
    final client = await _client();
    final flow = openid.Flow.authorizationCodeWithPKCE(
      client,
      scopes: _scopes,
      state: started.state,
      codeVerifier: started.verifier,
    )..redirectUri = _authorizer.redirectUri;

    // A flow keeps only the scopes the provider says it supports, and drops the
    // rest without a word. Losing `openid` means what goes out is not a sign-in
    // request at all, and the failure would surface much later as a provider
    // refusing a code for no stated reason.
    if (!flow.scopes.contains('openid')) {
      throw OidcException(
        'the provider at ${_config.issuer} does not offer the openid scope,'
        ' so it cannot be signed in to',
      );
    }

    return flow;
  }

  /// Keeps what the provider sent, so that the next start does not have to ask
  /// for it again.
  Future<void> _keep(openid.Credential credential) async {
    final response = credential.response;
    if (response == null) {
      return;
    }
    await _store.writeSetting(_tokenKey, jsonEncode(response));
  }

  /// What this device is holding, as something that can be spent and refreshed.
  Future<openid.Credential?> _heldCredential() async {
    final json = await _store.readSetting(_tokenKey);
    if (json == null) {
      return null;
    }

    final Map<String, dynamic> token;
    try {
      token = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      await _forgetTokens();
      return null;
    }

    final client = await _client();
    return client.createCredential(
      accessToken: token['access_token'] as String?,
      tokenType: token['token_type'] as String?,
      refreshToken: token['refresh_token'] as String?,
      idToken: token['id_token'] as String?,
      // The expiry the provider gave, as it gave it: this is written back as
      // it is read, so bringing it forward here would bring it forward again
      // every time. The slack is allowed for where it is checked — see
      // [_isSpent].
      expiresAt: _expiryOf(token),
    );
  }

  static DateTime? _expiryOf(Map<String, dynamic> token) {
    final at = token['expires_at'];
    if (at is int) {
      // Seconds since the epoch, which is how a token response states it.
      return DateTime.fromMillisecondsSinceEpoch(at * 1000);
    }
    return null;
  }

  Future<void> _forgetTokens() async {
    await _store.writeSetting(_tokenKey, null);
  }

  /// Throws away the access token and keeps the refresh token, so that the next
  /// token asked for is a refreshed one.
  Future<void> _forgetAccessToken() async {
    final json = await _store.readSetting(_tokenKey);
    if (json == null) {
      return;
    }
    try {
      final token = jsonDecode(json) as Map<String, dynamic>
        ..remove('access_token')
        ..remove('expires_at')
        ..remove('expires_in');
      await _store.writeSetting(
        _tokenKey,
        token['refresh_token'] == null ? null : jsonEncode(token),
      );
    } catch (_) {
      await _forgetTokens();
    }
  }

  Future<_FlowState?> _readFlowState() async {
    final json = await _store.readSetting(_flowStateKey);
    if (json == null) {
      return null;
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final returnTo = map['return_to'];
      return _FlowState(
        '${map['state']}',
        '${map['verifier']}',
        returnTo: returnTo is String ? Uri.tryParse(returnTo) : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// What the provider says about the user right now.
  Future<UserInfo?> getUserInfo() async {
    final token = await getActiveAccessToken();
    if (token == null) {
      return null;
    }

    // Asked for over the wire with the access token rather than read out of a
    // token this app decoded itself. What a provider will say to a bearer of
    // this token is the thing being asked about, and it is also the answer that
    // cannot be wrong about itself.
    var response = await _askUserInfo(token);
    if (response.statusCode == 401) {
      // Refused by the provider, however long this device thinks the token has
      // left: revoked, or the session behind it ended somewhere else. Kept, it
      // would be handed over again at every start until it ran out on its own,
      // so it is spent now — refreshed if there is a refresh token to do it
      // with, and signed in for again if not.
      await _forgetAccessToken();
      final fresh = await getFreshAccessToken();
      if (fresh == null) {
        return null;
      }
      response = await _askUserInfo(fresh);
    }
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

  Future<http.Response> _askUserInfo(String token) => _http.get(
        _config.userInfoEndpoint,
        headers: {'Authorization': 'Bearer $token'},
      );

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
      final response = await _http
          .get(_config.healthzEndpoint)
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (error) {
      return false;
    }
  }

  /// Where to send the browser to end the session at the provider as well.
  ///
  /// `null` when the provider does not say it has anywhere for that, which is
  /// its right — in which case [forgetUser] is the whole of what can be done.
  ///
  /// Not called by anything yet. It is here because it is the missing half of
  /// signing out: this app can forget a user, and until somebody sends the
  /// browser here, the provider has not.
  Future<Uri?> endSessionUrl({Uri? returnTo}) async {
    final credential = await _heldCredential();
    if (credential == null) {
      return null;
    }
    return credential.generateLogoutUrl(redirectUri: returnTo);
  }

  /// Forgets who is signed in on this device.
  ///
  /// It signs nobody out at the provider — that is the provider's own business,
  /// and this app is in no position to speak for it. What it does is make the
  /// next visit ask again from the beginning, which is the way out of a token
  /// or a set of roles that has gone stale. See [endSessionUrl] for the other
  /// half.
  ///
  /// The scores and sets on this device are left alone: they are what makes the
  /// app work without a network, and they are no use to anyone who cannot get a
  /// token to read them with anyway.
  Future<void> forgetUser() async {
    _signInFailure = null;
    await _forgetTokens();
    await _store.writeSetting(_flowStateKey, null);
    await _store.writeSetting(_userInfoKey, null);
  }
}

class OidcException implements Exception {
  OidcException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// THE FLOW
// ---------------------------------------------------------------------------

/// What this device has to remember while the user is away at the provider: the
/// secret it will prove the code with, and the state it will know its own
/// answer by.
class _FlowState {
  const _FlowState(
    this.state,
    this.verifier, {
    this.returnTo,
  });

  final String state;
  final String verifier;

  /// Where the user was when they were sent to sign in.
  final Uri? returnTo;
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

  factory UserInfo.fromClaims(
    Map<String, dynamic> claims,
    String rolesKey,
  ) {
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

  factory UserInfo.fromJson(
    Map<String, dynamic> json,
  ) => UserInfo(
        name: json['name'] as String?,
        subject: json['subject'] as String?,
        email: json['email'] as String?,
        roles: (json['roles'] as Map?)?.cast<String, dynamic>(),
        claims: (json['claims'] as Map?)?.cast<String, dynamic>(),
        rolesKey: json['rolesKey'] as String?,
      );

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'subject': subject,
        'email': email,
        'roles': roles,
        'claims': claims,
        'rolesKey': rolesKey,
      };
}

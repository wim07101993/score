import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart' as openid;
import 'package:score/config.dart';
import 'package:score/features/auth/authorizer.dart';
import 'package:score/features/auth/tab_lock.dart';
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
/// Signing out throws them away, which is what the profile page is for — and
/// since they outlive the tab, a device somebody else will use next is only
/// safe to walk away from once that has been done. See [signOut].
const List<String> _scopes = ['openid', 'email', 'profile', 'offline_access'];

const _tokenKey = 'auth_token_response';
const _userInfoKey = 'app_user_info';

/// Set when the user signed out, until the next sign-in finishes: see
/// [OidcApi.signOut].
const _signedOutKey = 'auth_signed_out';

/// Whose sets and collections this device holds: see [OidcApi.dataOwner].
const _dataOwnerKey = 'data_owner';

/// Where what a sign-in has to remember while the user is away is kept: one
/// record per sign-in, by its state.
///
/// Per sign-in, because on the web every tab of the app shares the one store
/// but not the one program. Two tabs that each send the user to sign in would
/// otherwise each write down their own flow over the other's, and whichever
/// came back first would be refused for a state that is not its own — and
/// throw the other's away on its way out.
const _flowStatePrefix = 'auth_flow_state';
String _flowStateKey(String state) => '$_flowStatePrefix:$state';

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
    Duration? otherTabsGrace,
  })  : _http = client ?? http.Client(),
        _authorizer = authorizer ?? Authorizer(_config),
        _otherTabsGrace = otherTabsGrace ??
            (kIsWeb ? const Duration(seconds: 2) : Duration.zero);

  final OidcConfig _config;
  final LocalStore _store;
  final http.Client _http;
  final Authorizer _authorizer;

  /// How long a refused refresh token is watched for another tab's
  /// replacement before it is given up on (see [_refreshNow]). Only the web
  /// has tabs.
  final Duration _otherTabsGrace;

  Future<openid.Client>? _clientFuture;

  /// The provider, as this app talks to it.
  ///
  /// Worked out once and held: discovery is a request, and every call that
  /// wants a token would otherwise make it again.
  Future<openid.Client> _client() =>
      _clientFuture ??= _describeProvider().then(
        (issuer) => openid.Client(issuer, _config.clientIdHere, httpClient: _http),
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
  ///
  /// [signIn] false is for everything that runs behind the user's back — a
  /// sync, a queued write going out. Those answer `null` rather than send the
  /// user to the provider: on the web a sign-in is the page leaving, taking
  /// whatever was being typed with it, and on a desktop it is a browser opening
  /// out of nowhere and a write waiting minutes on it. Worse, a token the API
  /// keeps refusing would be signed in for, refused, and signed in for again,
  /// with nobody asking for any of it. Signing in is for the app starting and
  /// the user asking — see [App.updateAuth].
  Future<String?> getActiveAccessToken({bool signIn = true}) async {
    final held = await _heldToken();
    if (held != null) {
      return held;
    }
    return await getFreshAccessToken(signIn: signIn);
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
  /// with, the refresh token this device is holding, or — when [signIn] — by
  /// asking them.
  Future<String?> getFreshAccessToken({bool signIn = true}) async {
    final finished = await (_finishing ??=
        _finishPendingSignIn().whenComplete(() => _finishing = null));
    if (finished != null) {
      return finished;
    }

    final refreshed = await _refresh();
    if (refreshed != null) {
      return refreshed;
    }

    if (!signIn || _signInFailure != null) {
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
      if (error case AuthorizationRefused(:final state?)) {
        await _store.writeSetting(_flowStateKey(state), null);
      }
      _signInFailure = error;
      return null;
    }
    if (callback == null) {
      return null;
    }

    // Read before the exchange, which throws the flow away once it is done.
    final started = await _readFlowState(callback.state);
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
  ///
  /// Other tabs of the web app are waited for too (see [underTabLock]): a tab
  /// that refreshes after another has finished reads back the token that one
  /// wrote down, rather than spending the same refresh token a second time.
  Future<String?> _refresh() => _refreshing ??=
      underTabLock('score-token-refresh', _refreshNow)
          .whenComplete(() => _refreshing = null);

  /// Keeps whatever came back: a provider that rotates refresh tokens hands a
  /// new one out with every refresh, and a device that did not write it down
  /// cannot refresh twice.
  ///
  /// The refresh token is only forgotten when the provider says it is no good.
  /// A refresh that failed because the network did is the same refresh token
  /// working fine the next time there is one, and throwing it away would make
  /// a player sign in again over a dropped connection.
  ///
  /// Nor is it forgotten when it was refused for having just been spent by
  /// another tab of the app. On the web every tab refreshes on its own, out of
  /// the one store: two tabs opened again the next morning both find the token
  /// run out and both spend the same refresh token, and a provider that
  /// rotates them takes it only once. The tab that lost reads back what the
  /// other wrote down and goes on with that — rather than throwing it away and
  /// sending both tabs to sign in.
  ///
  /// What the other tab wrote down reaches this one's store a moment after it
  /// was written — the store hears of it from the other tab — and the refusal
  /// of the race it lost is often back before that. So the store is watched
  /// for it for a while ([_otherTabsGrace]) before the token is given up on;
  /// and what is forgotten then is only the refresh token that was refused,
  /// never one another tab has written over it since.
  Future<String?> _refreshNow({bool readBackIfRefused = true}) async {
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
      if (readBackIfRefused && await _replacedByAnotherTab(credential)) {
        return _refreshNow(readBackIfRefused: false);
      }
      await _forgetRefreshToken(credential.refreshToken!);
      return null;
    }
  }

  /// Whether another tab wrote down a different refresh token than the one in
  /// [spent], within [_otherTabsGrace].
  Future<bool> _replacedByAnotherTab(openid.Credential spent) async {
    final until = DateTime.now().add(_otherTabsGrace);
    while (true) {
      final now = await _heldRefreshToken();
      if (now != null && now != spent.refreshToken) {
        return true;
      }
      if (!DateTime.now().isBefore(until)) {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// The refresh token in the store, read as it is rather than as a credential:
  /// no provider has to be reached to read it.
  Future<String?> _heldRefreshToken() async {
    final json = await _store.readSetting(_tokenKey);
    if (json == null) {
      return null;
    }
    try {
      return (jsonDecode(json) as Map<String, dynamic>)['refresh_token']
          as String?;
    } catch (_) {
      return null;
    }
  }

  /// Forgets what this device holds, if it is still [refused]: a refresh
  /// token another tab has written over it since is that tab's, and good.
  Future<void> _forgetRefreshToken(String refused) async {
    final held = await _heldRefreshToken();
    if (held == null || held == refused) {
      await _forgetTokens();
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
    final held = await _readFlowState(callback.state);
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
      await _store.writeSetting(_signedOutKey, null);
      return token;
    } finally {
      await _forgetFlowState(callback.state);
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
    // After signing out, the provider is asked to ask who it is rather than
    // wave the next person through on the session it still has for the last.
    final signedOut = await _store.readSetting(_signedOutKey) != null;
    final flow = await _flow(started, prompt: signedOut ? 'login' : null);

    // Written down before the user goes anywhere. On the web this app is about
    // to stop existing, and what comes back is worthless without these — and
    // the user is lost without the last one.
    await _store.writeSetting(
      _flowStateKey(started.state),
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
      // Nothing will come back for this sign-in any more: it was cancelled,
      // timed out, or refused, and on a device there is no later start of the
      // app for an answer to arrive in.
      await _store.writeSetting(_flowStateKey(started.state), null);
      return null;
    }
  }

  /// The authorization-code flow, built on [started].
  ///
  /// The same two values build the flow that goes out and the flow that reads
  /// the answer — which on the web are in two different lives of this app, and
  /// is the whole reason they are written down rather than kept in memory.
  ///
  /// [prompt] is sent to the provider as it is: `login` after the user signed
  /// out, see [signOut].
  Future<openid.Flow> _flow(_FlowState started, {String? prompt}) async {
    final client = await _client();
    final flow = openid.Flow.authorizationCodeWithPKCE(
      client,
      scopes: _scopes,
      state: started.state,
      codeVerifier: started.verifier,
      prompt: prompt,
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

  /// Whether the app was started with the provider's answer to a sign-in in
  /// its address, which has to be dealt with before anything else is shown.
  Future<bool> isFinishingASignIn() async {
    try {
      return await _authorizer.pendingCallback() != null;
    } catch (_) {
      // A refusal is an answer too.
      return true;
    }
  }

  /// Whether this device holds a token, or a refresh token to get one with.
  Future<bool> holdsAToken() async =>
      await _store.readSetting(_tokenKey) != null;

  Future<void> _forgetTokens() async {
    await _store.writeSetting(_tokenKey, null);
  }

  /// Throws away the access token and keeps the refresh token, so that the next
  /// token asked for is a refreshed one.
  ///
  /// For a token the API refused however long this device thinks it has left:
  /// revoked, or the session behind it ended somewhere else. Kept, it would be
  /// sent again with every request until it ran out on its own.
  Future<void> forgetAccessToken() async {
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

  /// What was written down when the sign-in with this [state] was started.
  ///
  /// Also where the build before this one wrote it down — one record for every
  /// sign-in — so that a sign-in that was out while the app was updated still
  /// finishes.
  Future<_FlowState?> _readFlowState(String state) async {
    final json = await _store.readSetting(_flowStateKey(state)) ??
        await _store.readSetting(_flowStatePrefix);
    if (json == null) {
      return null;
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['state'] != state) {
        return null;
      }
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

  Future<void> _forgetFlowState(String state) async {
    await _store.writeSetting(_flowStateKey(state), null);
    await _store.writeSetting(_flowStatePrefix, null);
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
      await forgetAccessToken();
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

  /// Forgets who is signed in on this device.
  ///
  /// It signs nobody out at the provider — that is the provider's own business,
  /// and this app is in no position to speak for it. What it does is make the
  /// next visit ask again from the beginning, which is the way out of a token
  /// or a set of roles that has gone stale. Ending the session at the provider
  /// as well is the missing other half, and nothing here does it yet.
  ///
  /// The scores and sets on this device are left alone: they are what makes the
  /// app work without a network, and a user who signs in again as themselves
  /// still has what they had not sent. Somebody else signing in is not handed
  /// them — see [dataOwner].
  Future<void> forgetUser() async {
    _signInFailure = null;
    await _forgetTokens();
    await _store.forgetSettingsStartingWith(_flowStatePrefix);
    await _store.writeSetting(_userInfoKey, null);
  }

  /// Forgets who is signed in, as [forgetUser] does, and has the next sign-in
  /// ask who it is.
  ///
  /// The tokens outlive the app being closed, so a shared or a borrowed device
  /// is only left to the next person once this has been done. The provider
  /// keeps a session of its own, which would sign the next person in as this
  /// one without asking; so the next sign-in asks it to ask again.
  Future<void> signOut() async {
    await forgetUser();
    await _store.writeSetting(_signedOutKey, 'true');
  }

  /// The subject of the user the sets and collections on this device belong
  /// to, or null when nobody has been recorded.
  ///
  /// What is kept here is somebody's: their private sets, the edits they have
  /// not sent, and how far their last pull read. Sent with another user's
  /// token, those would become that user's — so a sync only goes out while
  /// the user who is signed in is the one they belong to (see
  /// [holdsTheDataOfTheSignedInUser]), and a different user signing in has
  /// them forgotten first (see [App.updateAuth]).
  Future<String?> dataOwner() => _store.readSetting(_dataOwnerKey);

  Future<void> keepDataOwner(String? subject) =>
      _store.writeSetting(_dataOwnerKey, subject);

  /// Whether the sets and collections on this device may be synced with the
  /// token of the user who is signed in: whether they are that user's, or
  /// nobody's yet.
  ///
  /// Between another user signing in and the app having forgotten what the
  /// last one left, the user this device knows is not the one the data is
  /// recorded for, and nothing is sent.
  Future<bool> holdsTheDataOfTheSignedInUser() async {
    final owner = await dataOwner();
    if (owner == null) {
      return true;
    }
    return (await keptUserInfo())?.subject == owner;
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

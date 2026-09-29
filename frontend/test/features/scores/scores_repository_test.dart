import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/repository.dart';
import 'package:score/features/sembast/local_store.dart';

/// What a sync does with a document this device already holds.
///
/// A score changed within a window is in that window's answer and in no later
/// one. So a document that could not be fetched when its window came round is
/// only ever fetched again if the window is asked about again.

final _oidcConfig = OidcConfig(
  clientId: 'test',
  issuer: Uri.parse('http://nowhere'),
  redirectUri: Uri.parse('http://localhost/'),
  nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
  desktopRedirectUri: Uri.parse('http://localhost:7005/'),
  authorizationEndpoint: Uri.parse('http://nowhere/authorize'),
  tokenEndpoint: Uri.parse('http://nowhere/token'),
  userInfoEndpoint: Uri.parse('http://nowhere/userinfo'),
  healthzEndpoint: Uri.parse('http://nowhere/healthz'),
  rolesKey: 'roles',
);

class _SignedIn extends OidcApi {
  _SignedIn(
    LocalStore store,
  ) : super(_oidcConfig, store);

  @override
  Future<String?> getActiveAccessToken() async => 'a-token';
}

/// An API that lists what it is told to, and hands out documents until it is
/// told to stop.
class _Api extends ScoresApi {
  _Api() : super(ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  List<Map<String, dynamic>> answers = [];
  bool documentsFail = false;

  /// The change windows that were asked about, in order.
  final List<DateTime?> since = [];

  @override
  Future<List<Map<String, dynamic>>> listScores(
      DateTime? changesSince, DateTime? changesUntil, String authToken) async {
    since.add(changesSince);
    return answers;
  }

  @override
  Future<String> getScoreMusicXml(String scoreId, String authToken) async {
    if (documentsFail) {
      throw ScoresApiException('not now', null);
    }
    return '<new/>';
  }
}

void main() {
  test('a stale document that could not be fetched is tried again', () async {
    final store = await LocalStore.inMemory();
    final fetched = DateTime.utc(2026);
    await store.writeScores([
      Score(
        id: 'abc',
        lastChangedAt: fetched,
        lastSyncedAt: fetched,
        lastFetchedFileAt: fetched,
      ).toJson(),
    ]);
    await store.writeMusicXml('abc', '<old/>');

    final api = _Api()
      ..documentsFail = true
      ..answers = [
        {'id': 'abc', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    final scores = ScoresRepository(store, api, _SignedIn(store));
    await scores.init();

    await scores.syncWithApi();
    expect(await store.readMusicXml('abc'), '<old/>');

    // The window was not closed, so it is asked about again.
    api.documentsFail = false;
    await scores.syncWithApi();
    expect(api.since, [fetched, fetched]);
    expect(await store.readMusicXml('abc'), '<new/>');

    // And now it is.
    api.answers = [];
    await scores.syncWithApi();
    expect(api.since.last, isNot(fetched));
  });
}

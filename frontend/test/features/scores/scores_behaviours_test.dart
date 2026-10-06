import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/background.dart';
import 'package:score/behaviours/in_turn.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/scores/behaviours/ensure_score.dart';
import 'package:score/features/scores/behaviours/forget_gone_scores.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/kept_scores.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/storage/scores_api.dart';

import '../../test_stores.dart';

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

class _SignedIn({
  required Stores store,
}) extends OidcApi {
  this : super(config: _oidcConfig, store: store.auth);

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async => 'a-token';
}

/// An API that lists what it is told to, and hands out documents until it is
/// told to stop.
class _Api() extends ScoresApi {
  this : super(config: ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  List<Map<String, dynamic>> answers = [];
  bool documentsFail = false;

  /// The scores the server no longer has.
  Set<String> gone = {};

  @override
  Future<bool> canBeReached() async => true;

  /// The change windows that were asked about, in order.
  final List<DateTime?> since = [];
  final List<DateTime?> until = [];

  @override
  Future<List<Map<String, dynamic>>> listScores(
      DateTime? changesSince, DateTime? changesUntil, String authToken) async {
    since.add(changesSince);
    until.add(changesUntil);
    return answers;
  }

  @override
  Future<String?> getScoreMusicXml(String scoreId, String authToken) async {
    if (gone.contains(scoreId)) {
      return null;
    }
    if (documentsFail) {
      throw ScoresApiException(message: 'not now', status: null);
    }
    return '<new/>';
  }
}

/// The scores behaviours over one store and one API, as the app wires them:
/// a sync and the search for what is gone share one turn.
class _Scores({
  required final Stores store,
  required final ScoresApi api,
}) {
  late final OidcApi _oidc = _SignedIn(store: store);
  late final KeptScores _kept = KeptScores(
    store: store.scores,
    documents: store.documents,
  );
  late final InTurn _turn = InTurn();
  late final EnsureScore _ensureScore =
      EnsureScore(kept: _kept, api: api, oidc: _oidc);

  Future<void> syncWithApi() =>
      SyncScores(
        logger: Logger('test'),
        documents: store.documents,
        kept: _kept,
        api: api,
        oidc: _oidc,
        turn: _turn,
      ).action(null);

  Future<void> forgetWhatTheServerNoLongerHas() =>
      ForgetGoneScores(
        logger: Logger('test'),
        kept: _kept,
        api: api,
        oidc: _oidc,
        turn: _turn,
      ).action(null);

  Future<String?> getMusicXml(String scoreId) => GetMusicXml(
        logger: Logger('test'),
        documents: store.documents,
        kept: _kept,
        api: api,
        oidc: _oidc,
        ensureScore: _ensureScore,
        background: Background(logger: Logger('test')),
      ).action(scoreId, null);

  Future<void> markViewed(String scoreId) =>
      MarkScoreViewed(store: store.scores, ensureScore: _ensureScore)
          .action(scoreId, null);

  Future<Score?> getScore(String scoreId) => _kept.get(scoreId);

  Future<List<String>> ids() async => [...(await _kept.all()).keys];
}

void main() {
  test('a stale document that could not be fetched is tried again', () async {
    final store = await Stores.inMemory();
    final fetched = DateTime.utc(2026);
    await store.scores.writeAll([
      Score(
        id: 'abc',
        lastChangedAt: fetched,
        lastSyncedAt: fetched,
        lastFetchedFileAt: fetched,
      ).toJson(),
    ]);
    await store.documents.write('abc', '<old/>');

    final api = _Api()
      ..documentsFail = true
      ..answers = [
        {'id': 'abc', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    final scores = _Scores(store: store, api: api);

    await scores.syncWithApi();
    expect(await store.documents.read('abc'), '<old/>');

    // The window was not closed, so it is asked about again.
    api.documentsFail = false;
    await scores.syncWithApi();
    final asked = fetched.subtract(SyncScores.syncOverlap);
    expect(api.since, [asked, asked]);
    expect(await store.documents.read('abc'), '<new/>');

    // And now it is.
    api.answers = [];
    await scores.syncWithApi();
    expect(api.since.last, isNot(asked));
  });

  test('refreshing a document keeps when the score was last opened', () async {
    // The download is on its way when the player opens the score, and the
    // copy the refresh started from knows nothing about that.
    final store = await Stores.inMemory();
    final fetched = DateTime.utc(2026);
    await store.scores.writeAll([
      Score(id: 'abc', lastChangedAt: fetched, lastFetchedFileAt: fetched)
          .toJson(),
    ]);
    await store.documents.write('abc', '<old/>');
    late _Scores scores;
    final api = _OpensWhileFetching(meanwhile: () => scores.markViewed('abc'))
      ..answers = [
        {'id': 'abc', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    scores = _Scores(store: store, api: api);

    await scores.syncWithApi();

    expect((await scores.getScore('abc'))!.lastViewedAt, isNotNull);
  });

  test('a score the server no longer has is forgotten when opened', () async {
    final store = await Stores.inMemory();
    await store.scores.writeAll([const Score(id: 'abc').toJson()]);
    final api = _Api()..gone = {'abc'};
    final scores = _Scores(store: store, api: api);

    await expectLater(
      scores.getMusicXml('abc'),
      throwsA(isA<ScoresApiException>()
          .having((error) => error.status, 'status', 404)),
    );

    expect(await scores.getScore('abc'), isNull);
    expect(await store.scores.readAll(), isEmpty);
  });

  test('the scores the server does not list are forgotten', () async {
    final store = await Stores.inMemory();
    await store.scores.writeAll([
      const Score(id: 'kept').toJson(),
      const Score(id: 'gone').toJson(),
    ]);
    await store.documents.write('gone', '<old/>');
    final api = _Api()
      ..answers = [
        {'id': 'kept', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    final scores = _Scores(store: store, api: api);

    await scores.forgetWhatTheServerNoLongerHas();

    expect(api.since, [null], reason: 'not every score was asked for');
    // Not up to this device's now, which may be behind the server's.
    expect(
      api.until.single!.isAfter(DateTime.now().add(const Duration(days: 365))),
      isTrue,
    );
    expect(await scores.ids(), ['kept']);
    expect(await store.documents.has('gone'), isFalse);
  });

  test('a score forgotten is not brought back by a sync asked for before',
      () async {
    // The sync is asked for first and its listing answers last: run side by
    // side, it would write back the score the search for what is gone has
    // just forgotten.
    final store = await Stores.inMemory();
    await store.scores.writeAll([const Score(id: 'gone').toJson()]);
    final api = _SlowFirstListing()
      ..answers = [
        {'id': 'gone', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    final scores = _Scores(store: store, api: api);

    final sync = scores.syncWithApi();
    final search = scores.forgetWhatTheServerNoLongerHas();
    // The sync has its answer; by the time the search asks, the server has
    // lost the score.
    await api.asked.future;
    api.answers = [];
    api.release.complete();
    await Future.wait([sync, search]);

    expect(await scores.getScore('gone'), isNull);
    expect(api.since, [null, null]);
  });

  test('a sync that finds nothing new writes nothing', () async {
    final store = await Stores.inMemory();
    final api = _Api()
      ..answers = [
        {'id': 'abc', 'last_changed_at': '2026-02-01T00:00:00Z'},
      ];
    final scores = _Scores(store: store, api: api);
    await scores.syncWithApi();

    final notifier = ScoresNotifier(store: store.scores);
    addTearDown(notifier.dispose);
    await notifier.ready;
    var told = 0;
    notifier.addListener(() => told++);
    // The window starts before the newest score, so it is read back again.
    await scores.syncWithApi();
    await Future<void>.delayed(Duration.zero);

    expect(told, 0, reason: 'every page was redrawn for nothing');
  });
}

/// An API whose first listing says it was [asked] and then waits for
/// [release], answering with what it was told when it was asked.
class _SlowFirstListing extends _Api {
  final asked = Completer<void>();
  final release = Completer<void>();
  var _first = true;

  @override
  Future<List<Map<String, dynamic>>> listScores(
      DateTime? changesSince, DateTime? changesUntil, String authToken) async {
    final answer =
        await super.listScores(changesSince, changesUntil, authToken);
    if (_first) {
      _first = false;
      asked.complete();
      await release.future;
    }
    return answer;
  }
}

/// An API whose document download lets the player open the score while it is
/// on its way.
class _OpensWhileFetching({
  required final Future<void> Function() meanwhile,
}) extends _Api {
  @override
  Future<String?> getScoreMusicXml(String scoreId, String authToken) async {
    await meanwhile();
    return super.getScoreMusicXml(scoreId, authToken);
  }
}

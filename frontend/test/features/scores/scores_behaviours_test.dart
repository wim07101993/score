import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/get_score.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/work.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/sync/models/syncable.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';

import '../../test_api.dart';
import '../../test_auth.dart';
import '../../test_stores.dart';

/// An API that lists what it is told to, and hands out scores and documents.
class _Api() extends ScoresApi {
  this : super(clientFactory: testClientFactory());

  /// What a listing answers with.
  List<Score> answers = [];

  /// What asking for a single score answers with, by id.
  final Map<String, Score> scores = {};

  /// Whether an upload gets through.
  bool uploadsFail = false;

  /// What was uploaded, by id.
  final Map<String, String> uploaded = {};

  /// The change windows that were asked about, in order.
  final List<DateTime> since = [];

  @override
  Future<bool> canBeReached() async => true;

  @override
  Future<SyncChanges<Score>> listChanges({
    required DateTime since,
    DateTime? until,
  }) async {
    this.since.add(since);
    return (changed: answers, deleted: const <DeletedEntity>[]);
  }

  @override
  Future<Score?> getScore(String scoreId) async => scores[scoreId];

  @override
  Future<String?> getScoreMusicXml(String scoreId) async => '<new/>';

  @override
  Future<void> putScore(String scoreId, String musicXml) async {
    if (uploadsFail) {
      throw ApiException(
        message: 'nothing answered',
        statusCode: null,
        problem: null,
      );
    }
    uploaded[scoreId] = musicXml;
  }
}

/// The scores behaviours over one store and one API, as the app wires them.
class _Scores({
  required final Stores store,
  required final _Api api,
}) {
  late final _cacheScore = CacheScore(db: store.scores);
  late final _cacheMusicXml = CacheMusicXml(files: store.documents);
  late final _getScore = GetScore(
    api: api,
    db: store.scores,
    cache: _cacheScore,
  );

  Future<void> sync() async => SyncScores(
    logger: Logger('test'),
    authNotifier: await signedIn(),
    db: store.scores,
    api: api,
    syncDates: store.syncDates,
  ).action(null);

  Future<Score?> getScore(String scoreId) => _getScore.action(scoreId, null);

  Future<String?> getMusicXml(String scoreId) => GetMusicXml(
    logger: Logger('test'),
    files: store.documents,
    api: api,
    cache: _cacheMusicXml,
  ).action(scoreId, null);

  Future<void> markViewed(String scoreId) => MarkScoreViewed(
    store: store.scores,
    getScore: _getScore,
  ).action(scoreId, null);

  Future<void> upload(String scoreId, String musicXml) => UploadScore(
    logger: Logger('test'),
    documents: store.documents,
    db: store.scores,
    api: api,
    cacheScore: _cacheScore,
    cacheMusicXml: _cacheMusicXml,
  ).action((scoreId, musicXml), null);
}

/// Lets what was left to run in the background — a score or a document being
/// cached — finish.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _musicXml = '''
<score-partwise version="4.0">
  <work><work-title>Après un rêve</work-title></work>
  <identification><creator type="composer">Gabriel Fauré</creator></identification>
  <part-list>
    <score-part id="P1"><part-name>Voice</part-name></score-part>
  </part-list>
  <part id="P1"><measure number="1"/></part>
</score-partwise>
''';

void main() {
  group('a sync', () {
    test('keeps what only this device knows about a score', () async {
      final store = await Stores.inMemory();
      final viewed = DateTime.utc(2026, 3);
      await store.scores.putAll([
        Score(
          id: 'abc',
          lastChangedAt: DateTime.utc(2026),
          lastViewedAt: viewed,
        ),
      ]);
      final api = _Api()
        ..answers = [Score(id: 'abc', lastChangedAt: DateTime.utc(2026, 2))];

      await _Scores(store: store, api: api).sync();

      final kept = await store.scores.get('abc');
      expect(kept!.lastChangedAt, DateTime.utc(2026, 2));
      expect(kept.lastViewedAt, viewed);
    });

    test('starts where the newest change the last one heard of was', () async {
      final store = await Stores.inMemory();
      final api = _Api()
        ..answers = [
          Score(id: 'a', lastChangedAt: DateTime.utc(2026)),
          Score(id: 'b', lastChangedAt: DateTime.utc(2026, 2)),
        ];
      final scores = _Scores(store: store, api: api);

      await scores.sync();
      api.answers = [];
      await scores.sync();
      await scores.sync();

      const overlap = Duration(seconds: 2);
      expect(api.since, [
        beginningOfTime.subtract(overlap),
        DateTime.utc(2026, 2).subtract(overlap),
        DateTime.utc(2026, 2).subtract(overlap),
      ]);
    });

    test('is not moved by a score stored on its own', () async {
      // Opened by a link, or read back after an upload: newer than anything
      // the last sync saw. Started after it, the next sync would skip whatever
      // else changed in between.
      final store = await Stores.inMemory();
      final api = _Api()
        ..answers = [Score(id: 'listed', lastChangedAt: DateTime.utc(2026))];
      final scores = _Scores(store: store, api: api);
      await scores.sync();

      await store.scores.putAll([
        Score(id: 'opened', lastChangedAt: DateTime.utc(2026, 6)),
      ]);
      api.answers = [];
      await scores.sync();

      expect(
        api.since.last,
        DateTime.utc(2026).subtract(const Duration(seconds: 2)),
      );
    });
  });

  group('a score that is not on this device', () {
    test('is fetched, and kept for next time', () async {
      final store = await Stores.inMemory();
      final api = _Api()
        ..scores['abc'] = Score(id: 'abc', lastChangedAt: DateTime.utc(2026));

      expect(
        (await _Scores(store: store, api: api).getScore('abc'))?.id,
        'abc',
      );
      await _settle();

      expect(await store.scores.get('abc'), isNotNull);
    });

    test('keeps when it was opened, however the caching lands', () async {
      // Marked as viewed before the copy that was fetched is written down:
      // the copy knows nothing about it.
      final store = await Stores.inMemory();
      final api = _Api()
        ..scores['abc'] = Score(id: 'abc', lastChangedAt: DateTime.utc(2026));

      await _Scores(store: store, api: api).markViewed('abc');
      await _settle();

      expect((await store.scores.get('abc'))!.lastViewedAt, isNotNull);
    });
  });

  group('a document', () {
    test('that is on this device is read from it', () async {
      final store = await Stores.inMemory();
      await store.documents.write('abc', '<held/>');

      expect(
        await _Scores(store: store, api: _Api()).getMusicXml('abc'),
        '<held/>',
      );
    });

    test('that is not is fetched, and kept for next time', () async {
      final store = await Stores.inMemory();

      expect(
        await _Scores(store: store, api: _Api()).getMusicXml('abc'),
        '<new/>',
      );
      await _settle();

      expect(await store.documents.read('abc'), '<new/>');
    });
  });

  group('an upload', () {
    test('is read back the way the server has it', () async {
      final store = await Stores.inMemory();
      final api = _Api()
        ..scores['abc'] = Score(
          id: 'abc',
          lastChangedAt: DateTime.utc(2026, 5),
          work: const Work(title: 'As the server read it'),
        );

      await _Scores(store: store, api: api).upload('abc', _musicXml);
      await _settle();

      expect(api.uploaded['abc'], _musicXml);
      expect(await store.documents.read('abc'), _musicXml);
      expect((await store.scores.get('abc'))!.title, 'As the server read it');
    });

    test('that does not get through is still on this device', () async {
      final store = await Stores.inMemory();
      final api = _Api()..uploadsFail = true;

      await expectLater(
        _Scores(store: store, api: api).upload('abc', _musicXml),
        throwsA(isA<ApiException>()),
      );
      await _settle();

      expect((await store.scores.get('abc'))!.title, 'Après un rêve');
      expect(await store.documents.read('abc'), _musicXml);
    });
  });
}

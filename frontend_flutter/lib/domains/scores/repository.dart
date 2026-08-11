import 'package:flutter/foundation.dart';

import '../../data/local_store.dart';
import '../auth/oidc_api.dart';
import 'api.dart';
import 'models.dart';

/// The scores, as this device has them.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. That is what makes the app work on a stage, and it is why
/// this is the only thing a page talks to: the API and the store are both
/// behind it.
class ScoresRepository extends ChangeNotifier {
  ScoresRepository(this._store, this._api, this._oidc);

  final LocalStore _store;
  final ScoresApi _api;
  final OidcApi _oidc;

  final Map<String, Score> _scores = {};

  /// Every score this device knows, most recently opened first: what was played
  /// last is what is likely to be played next.
  List<Score> get scores {
    final all = _scores.values.toList();
    all.sort((a, b) {
      final byViewed = (b.lastViewedAt ?? DateTime.utc(1970))
          .compareTo(a.lastViewedAt ?? DateTime.utc(1970));
      return byViewed != 0 ? byViewed : a.title.compareTo(b.title);
    });
    return all;
  }

  Score? getScore(String scoreId) => _scores[scoreId];

  Future<void> init() async {
    for (final record in await _store.readScores()) {
      final score = Score.fromJson(record);
      _scores[score.id] = score;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Reads in everything that changed on the server since it last said
  /// anything, and fetches the documents of any score whose document this
  /// device is holding an old copy of.
  Future<void> syncWithApi() async {
    final token = await _oidc.getActiveAccessToken();
    if (token == null) {
      return;
    }

    final fromApi = await _api.listScores(_lastSyncedAt(), DateTime.now(), token);
    if (fromApi.isEmpty) {
      return;
    }

    final incoming = [
      for (final json in fromApi)
        Score.fromApi(json, existing: _scores[json['id']]),
    ];
    await _keep(incoming);

    // A score whose document is not on this device is left alone: it is fetched
    // when it is opened. One whose document *is* here and has been uploaded
    // again since is fetched now, so that the player who has it downloaded has
    // the version the band is playing from.
    for (final score in incoming) {
      final fetched = score.lastFetchedFileAt;
      if (fetched == null) continue;
      if (!(score.lastChangedAt ?? DateTime.utc(1970)).isAfter(fetched)) {
        continue;
      }

      final accessToken = await _oidc.getActiveAccessToken();
      if (accessToken == null) return;

      final musicXml = await _api.getScoreMusicXml(score.id, accessToken);
      await _store.writeMusicXml(score.id, musicXml);
      await _keep([score.copyWith(lastFetchedFileAt: DateTime.now())]);
    }
  }

  /// Where the next change window starts. `null` when the server has never said
  /// anything, which asks about everything there has ever been.
  DateTime? _lastSyncedAt() {
    DateTime? latest;
    for (final score in _scores.values) {
      final synced = score.lastSyncedAt;
      if (synced != null && (latest == null || synced.isAfter(latest))) {
        latest = synced;
      }
    }
    return latest;
  }

  /// Stores scores, keeping whichever of the two is newer. A score the server
  /// describes as older than the one here is an answer that arrived out of
  /// order.
  Future<void> _keep(List<Score> scores) async {
    final toStore = <Score>[];
    for (final score in scores) {
      final existing = _scores[score.id];
      if (existing != null &&
          (existing.lastChangedAt ?? DateTime.utc(1970))
              .isAfter(score.lastChangedAt ?? DateTime.utc(1970))) {
        continue;
      }
      toStore.add(score);
      _scores[score.id] = score;
    }

    if (toStore.isEmpty) {
      return;
    }
    await _store.writeScores([for (final score in toStore) score.toJson()]);
    notifyListeners();
  }

  /// The score with the given id, asking the API for that one score when it is
  /// not known here.
  ///
  /// A sync only ever asks for what changed since the last one, and the API
  /// answers on when a score last changed rather than on when this app last
  /// heard of it. So a score that is missing locally and was last changed
  /// before the most recent sync is in no answer a sync will ever get: it has
  /// to be asked for by its id, or it stays missing for good.
  Future<Score?> ensureScore(String scoreId) async {
    final known = _scores[scoreId];
    if (known != null) {
      return known;
    }

    if (!await _api.canBeReached()) {
      return null;
    }
    final token = await _oidc.getActiveAccessToken();
    if (token == null) {
      return null;
    }

    final fromApi = await _api.getScore(scoreId, token);
    if (fromApi == null) {
      return null;
    }
    await _keep([Score.fromApi(fromApi)]);
    return _scores[scoreId];
  }

  // -------------------------------------------------------------------------
  // THE DOCUMENTS
  // -------------------------------------------------------------------------

  /// The document of one score: from this device if it is here, and from the
  /// API otherwise. `null` when it is neither here nor reachable.
  Future<String?> getMusicXml(String scoreId) async {
    if (await _store.hasMusicXml(scoreId)) {
      final held = await _store.readMusicXml(scoreId);
      if (held != null) {
        // Asked for in the background rather than waited on: the score is
        // already on screen by then, and what this adds is its title.
        unawaited(ensureScore(scoreId));
        return held;
      }
    }

    if (!await _api.canBeReached()) {
      return null;
    }
    final token = await _oidc.getActiveAccessToken();
    if (token == null) {
      return null;
    }

    final musicXml = await _api.getScoreMusicXml(scoreId, token);
    await _store.writeMusicXml(scoreId, musicXml);

    final score = await ensureScore(scoreId);
    if (score != null) {
      await _keep([score.copyWith(lastFetchedFileAt: DateTime.now())]);
    }
    return musicXml;
  }

  /// Uploads a score, which is what makes it a score the band has.
  Future<void> putMusicXml(String scoreId, String musicXml) async {
    final token = await _oidc.getActiveAccessToken();
    if (token == null) {
      throw ScoresApiException('you are not signed in', null);
    }
    await _api.putScore(scoreId, token, musicXml);
    await _store.writeMusicXml(scoreId, musicXml);
  }

  /// Says that this score was just looked at, which is what the list is sorted
  /// by.
  Future<void> markViewed(String scoreId) async {
    final score = await ensureScore(scoreId);
    if (score == null) {
      return;
    }
    final viewed = score.copyWith(lastViewedAt: DateTime.now());
    _scores[scoreId] = viewed;
    await _store.writeScores([viewed.toJson()]);
    notifyListeners();
  }
}

/// Starting something and not waiting for it, said out loud so that a reader
/// knows it was meant.
void unawaited(Future<void> future) {
  future.catchError((Object error) {
    debugPrint('a background task failed: $error');
  });
}

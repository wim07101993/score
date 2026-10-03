import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:score/background.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/sembast/local_store.dart';

final _log = Logger('Scores');

/// The scores, as this device has them.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. That is what makes the app work on a stage, and it is why
/// this is the only thing a page talks to: the API and the store are both
/// behind it.
class ScoresRepository extends ChangeNotifier {
  ScoresRepository(
    this._store,
    this._api,
    this._oidc,
  );

  final LocalStore _store;
  final ScoresApi _api;
  final OidcApi _oidc;

  final Map<String, Score> _scores = {};

  /// [scores] as it was last sorted, or null when [_scores] has changed since.
  /// Every page that lists scores asks for them on every rebuild, and a filter
  /// rebuilds on every key typed; sorting the whole library each time is
  /// work that only a change to it makes necessary. Anything that writes to
  /// [_scores] sets this back to null.
  List<Score>? _sorted;

  /// Every score this device knows, most recently opened first: what was played
  /// last is what is likely to be played next.
  ///
  /// It cannot be changed: it is the same list for every caller until the
  /// scores change.
  List<Score> get scores {
    final cached = _sorted;
    if (cached != null) {
      return cached;
    }
    final all = _scores.values.toList();
    all.sort((a, b) {
      final byViewed = (b.lastViewedAt ?? DateTime.utc(1970))
          .compareTo(a.lastViewedAt ?? DateTime.utc(1970));
      return byViewed != 0 ? byViewed : a.title.compareTo(b.title);
    });
    return _sorted = List.unmodifiable(all);
  }

  Score? getScore(String scoreId) => _scores[scoreId];

  Future<void> init() async {
    for (final record in await _store.readScores()) {
      final score = Score.fromJson(record);
      _scores[score.id] = score;
    }
    _sorted = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Reads in everything that changed on the server since it last said
  /// anything, and fetches the documents of any score whose document this
  /// device is holding an old copy of.
  Future<void> syncWithApi() async {
    final token = await _oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      return;
    }

    // The window is asked about up to this device's now, but where it is
    // recorded to have ended is read off what the server answered: the server
    // filters on its own clock, and a device whose clock runs ahead would
    // otherwise record a watermark past edits the server has yet to make. The
    // overlap takes in a change whose moment was set before the newest one in
    // the answer but that only became visible after it was given.
    final fromApi = await _api.listScores(
      _lastSyncedAt()?.subtract(syncOverlap),
      DateTime.now(),
      token,
    );
    if (fromApi.isEmpty) {
      return;
    }

    // Kept without moving the watermark yet: what the server said is worth
    // showing straight away, but the window is only done once the documents it
    // made stale are fetched too.
    var incoming = [
      for (final json in fromApi)
        Score.fromApi(json, existing: _scores[json['id']]),
    ];
    await _keep(incoming);

    // A score whose document is not on this device is left alone: it is fetched
    // when it is opened. One whose document *is* here and has been uploaded
    // again since is fetched now, so that the player who has it downloaded has
    // the version the band is playing from.
    var refreshedAll = true;
    for (final score in incoming) {
      final fetched = score.lastFetchedFileAt;
      if (fetched == null) {
        // No version recorded is not the same as no document held: one that
        // was stored before its details could be read back has none, and is
        // exactly the one that can be out of date.
        if (!await _store.hasMusicXml(score.id)) continue;
      } else if (!(score.lastChangedAt ?? DateTime.utc(1970))
          .isAfter(fetched)) {
        continue;
      }

      try {
        final accessToken = await _oidc.getActiveAccessToken(signIn: false);
        if (accessToken == null) {
          refreshedAll = false;
          break;
        }

        final musicXml = await _api.getScoreMusicXml(score.id, accessToken);
        if (musicXml == null) {
          _log.info('the server no longer has score ${score.id}; forgetting it');
          // Listed a moment ago and gone by now: nothing left to refresh.
          await _forget(score.id);
          continue;
        }
        await _store.writeMusicXml(score.id, musicXml);
        // Onto the score as it is now rather than as it was before the
        // download: it may have been opened meanwhile, and a copy from before
        // would put back when it was last looked at.
        await _keep([
          (_scores[score.id] ?? score)
              .copyWith(lastFetchedFileAt: _fetchedAt(score)),
        ]);
      } catch (error, stackTrace) {
        // The others are still worth fetching, but this window is not done.
        _log.warning('the document of ${score.id} could not be refreshed',
            error, stackTrace);
        refreshedAll = false;
      }
    }

    // A score changed in this window is in no later window, so a document that
    // could not be fetched is only ever retried if the watermark stays put: the
    // next sync then asks for the same window again, and finds it stale again.
    if (!refreshedAll) {
      return;
    }
    DateTime? until;
    for (final score in incoming) {
      final changed = score.lastChangedAt;
      if (changed != null && (until == null || changed.isAfter(until))) {
        until = changed;
      }
    }
    if (until == null) {
      return;
    }
    incoming = [
      for (final score in incoming)
        (_scores[score.id] ?? score).copyWith(lastSyncedAt: until),
    ];
    await _keep(incoming);
  }

  /// Forgets every score this device knows that the server does not.
  ///
  /// [syncWithApi] only ever hears what changed, never what is gone, so a score
  /// the server no longer has — removed from its database, or from another
  /// server altogether — would stay in the list for good, and every set or
  /// collection it is put into would be refused for naming it. This asks for
  /// every score there is instead, which is more than a sync should cost, and
  /// so is only done when the player asks for everything to be synced.
  ///
  /// Only what was here before asking is forgotten: a score that arrived while
  /// the answer was on its way is not in it, and is not gone.
  Future<void> forgetWhatTheServerNoLongerHas() async {
    final token = await _oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      return;
    }
    final before = _scores.keys.toSet();
    final fromApi = await _api.listScores(null, DateTime.now(), token);
    final there = {for (final json in fromApi) json['id']};
    final gone = before.difference(there);
    if (gone.isNotEmpty) {
      _log.info('the server no longer has ${gone.length} of the scores on this'
          ' device; forgetting them: ${gone.join(', ')}');
    }
    for (final scoreId in gone) {
      await _forget(scoreId);
    }
  }

  /// How far back of the watermark a sync starts asking again. Whatever falls
  /// inside it twice is simply kept again.
  static const syncOverlap = Duration(minutes: 1);

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

  /// What a document just fetched is recorded as being fetched at: the moment
  /// the server says the score last changed, rather than this device's now.
  /// It is compared with that same moment later on, and a device whose clock
  /// runs ahead would otherwise never see an upload as newer than its copy.
  /// A document newer than that moment is only fetched once more for it.
  static DateTime _fetchedAt(Score score) =>
      score.lastChangedAt ?? DateTime.utc(1970);

  /// Stores scores, keeping whichever of the two is newer. A score the server
  /// describes as older than the one here is an answer that arrived out of
  /// order.
  ///
  /// One that is exactly what is here already is not written again: every
  /// sync reads the newest score back (its window starts before it), and
  /// writing it would redraw every page for nothing.
  Future<void> _keep(List<Score> scores) async {
    final toStore = <Score>[];
    for (final score in scores) {
      final existing = _scores[score.id];
      if (existing != null &&
          (existing.lastChangedAt ?? DateTime.utc(1970))
              .isAfter(score.lastChangedAt ?? DateTime.utc(1970))) {
        continue;
      }
      if (existing != null &&
          jsonEncode(existing.toJson()) == jsonEncode(score.toJson())) {
        continue;
      }
      toStore.add(score);
      _scores[score.id] = score;
      _sorted = null;
    }

    if (toStore.isEmpty) {
      return;
    }
    await _store.writeScores([for (final score in toStore) score.toJson()]);
    notifyListeners();
  }

  /// Forgets a score the server said it does not have, document and all.
  Future<void> _forget(String scoreId) async {
    await _store.forgetScore(scoreId);
    if (_scores.remove(scoreId) != null) {
      _sorted = null;
      notifyListeners();
    }
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
    final token = await _oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      return null;
    }

    final fromApi = await _api.getScore(scoreId, token);
    if (fromApi == null) {
      return null;
    }
    // What this device knows about the score and the server does not — when it
    // was last opened, when its document was fetched — is kept: it may have
    // been written while this was being asked.
    await _keep([Score.fromApi(fromApi, existing: _scores[scoreId])]);
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
        inTheBackground(ensureScore(scoreId));
        return held;
      }
    }

    if (!await _api.canBeReached()) {
      return null;
    }
    final token = await _oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      return null;
    }

    final musicXml = await _api.getScoreMusicXml(scoreId, token);
    if (musicXml == null) {
      _log.info('the server no longer has score $scoreId; forgetting it');
      // A listing only ever says what changed, never what was removed, so a
      // score the server no longer has stays in the list until it is asked for
      // by its id. It has been asked for now, and is forgotten.
      await _forget(scoreId);
      throw ScoresApiException(
        'This score is no longer on the server, and has been removed from this'
        ' device.',
        404,
      );
    }
    await _store.writeMusicXml(scoreId, musicXml);

    // The document is in hand by now, and what follows is only which version
    // of it this is: failing to find that out does not make the document any
    // less there to be played. Left unrecorded, the next sync fetches it again.
    try {
      final score = await ensureScore(scoreId);
      if (score != null) {
        await _keep([
          (_scores[scoreId] ?? score)
              .copyWith(lastFetchedFileAt: _fetchedAt(score)),
        ]);
      }
    } catch (error, stackTrace) {
      _log.warning('the score $scoreId could not be read back', error,
          stackTrace);
    }
    return musicXml;
  }

  /// Uploads a score, which is what makes it a score the band has.
  Future<void> putMusicXml(String scoreId, String musicXml) async {
    final token = await _oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      throw ScoresApiException('you are not signed in', null);
    }
    final before = _scores[scoreId]?.lastChangedAt;
    await _api.putScore(scoreId, token, musicXml);
    await _store.writeMusicXml(scoreId, musicXml);

    // Recorded as a copy held, or a sync would leave it be and this device
    // would never pick up a corrected upload from someone else. When the
    // server put this upload is not known here, so it is recorded as the
    // version before it: the next sync then fetches this same upload once,
    // which costs a download, rather than taking a later one for this one.
    try {
      final score = await ensureScore(scoreId);
      if (score != null) {
        await _keep([
          score.copyWith(lastFetchedFileAt: before ?? DateTime.utc(1970)),
        ]);
      }
    } catch (error, stackTrace) {
      // The upload itself went through; the score is read in on the next sync
      // and its document fetched when it is next opened.
      _log.warning('the score $scoreId could not be read back', error,
          stackTrace);
    }
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
    _sorted = null;
    await _store.writeScores([viewed.toJson()]);
    notifyListeners();
  }
}

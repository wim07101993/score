import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/files/file_saver.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/musicxml_view.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/download_score_button.dart';
import 'package:score/features/scores/widgets/next_score_button.dart';
import 'package:score/features/scores/widgets/open_collection_button.dart';
import 'package:score/features/scores/widgets/open_set_button.dart';
import 'package:score/features/scores/widgets/part_visibility_chip.dart';
import 'package:score/features/scores/widgets/previous_score_button.dart';
import 'package:score/features/scores/widgets/show_as_written_button.dart';
import 'package:score/features/scores/widgets/transpose_down_button.dart';
import 'package:score/features/scores/widgets/transpose_up_button.dart';
import 'package:score/features/scores/widgets/upload_score_button.dart';
import 'package:score/features/scores/widgets/zoom_in_button.dart';
import 'package:score/features/scores/widgets/zoom_out_button.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/router.dart';
import 'package:uuid/uuid.dart';

class const ScoreDetailPage({
  super.key,
  required final String scoreId,
  final String? setId,
  final String? collectionId,
  final String? entryId,
  final bool performing = false,
  final ScoreReadingHandover? handover,
}) extends StatefulWidget {
  static const paper = 'paper';

  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

class const ScoreReadingHandover({
  required final ScoreView view,
  required final double zoom,
  required final void Function(ScoreView view, double zoom) onReturn,
});

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  static const _uuid = Uuid();
  static const _writtenSpace = 7.5;
  static const _minSpace = _writtenSpace * ScoreViewSettings.minZoom;
  static const _maxSpace = _writtenSpace * ScoreViewSettings.maxZoom;

  static int _stands = 0;

  final _auth = GetIt.I<AuthNotifier>();
  final _settings = GetIt.I<SettingsNotifier>();
  final _sets = GetIt.I<SetsNotifier>();
  final _collections = GetIt.I<CollectionsNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  late final String _newScoreId = _uuid.v4();
  late final AppLifecycleListener _lifecycle;

  List<ScorePartRef> _parts = const [];
  String? _musicXml;
  String? _scoreId;
  ScoreView? _view;

  bool _loading = true;
  Object? _failure;
  double _space = _writtenSpace;
  double _pinched = 1;
  _SetContext? _set;
  _CollectionContext? _collection;

  bool get _isNew => widget.scoreId == 'new';
  bool get _isPaper => widget.scoreId == ScoreDetailPage.paper;
  String? get _entryScoreId => _isPaper ? null : widget.scoreId;
  Timer? _keeping;
  DateTime? _shownFetchedAt;

  @override
  void initState() {
    super.initState();
    _scoreId = _isNew || _isPaper ? null : widget.scoreId;
    _sets.addListener(_takeSetChanges);
    _collections.addListener(_takeCollectionChanges);
    _scores.addListener(_takeScoreChanges);
    // A tablet put away, or a tab put in the background, may not come back:
    // what the player changed is kept before it goes.
    _lifecycle = AppLifecycleListener(
      onHide: _keepWhatIsWaiting,
      onPause: _keepWhatIsWaiting,
    );
    // On the stand the score is all there is: the bars a device draws over the
    // top and the bottom of the screen are lines of music not shown. They come
    // back with a swipe from the edge, and for good once the stand is closed.
    if (widget.performing && _stands++ == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _keepWhatIsWaiting();
    if (widget.performing) {
      if (--_stands == 0) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      final view = _view;
      if (view != null) widget.handover?.onReturn(view, _zoom);
    }
    _lifecycle.dispose();
    _sets.removeListener(_takeSetChanges);
    _collections.removeListener(_takeCollectionChanges);
    _scores.removeListener(_takeScoreChanges);
    super.dispose();
  }

  /// The set as a sync or another page has it now. What the band plays it in,
  /// and where it comes in the gig, are the owner's to change while the page is
  /// open — and the reading kept against it is counted from the key the band
  /// plays it in, so a stale one would be kept wrong.
  ///
  /// So what the entry says about how the score is read is taken onto the
  /// screen as well, not only into the context: a band moved up a tone while
  /// the song is open is a band the player is now a tone below, and the next
  /// zoom would keep that as their own reading — down a tone from the band,
  /// from then on. See [_takeReading].
  void _takeSetChanges() {
    final context = _set;
    if (!mounted || context == null) return;
    final now = _sets.getSet(context.set.id);
    if (identical(now, context.set)) return;
    final index =
        now?.entries.indexWhere((entry) => entry.id == context.entry.id) ?? -1;
    // Taken out of the set, or the set deleted, while it is on the stand: the
    // score is still worth reading, but there is no running order around it
    // any more to show a place in, or to keep a reading against.
    if (now == null || index < 0) {
      _letGoOfTheEntry();
      return;
    }
    final entry = now.entries[index];
    // The same check as when the page was opened: an entry written to play a
    // different score while this one is open is not this score's any more,
    // and neither are its key and its parts.
    if (entry.scoreId != _entryScoreId) {
      _letGoOfTheEntry(scannedAs: entry.scoreId);
      return;
    }
    setState(() {
      _set = _SetContext(set: now, index: index);
      _takeReading(
        was: _Reading.ofSong(entry: context.entry),
        now: _Reading.ofSong(entry: entry),
      );
    });
  }

  /// The same as [_takeSetChanges], for a collection.
  void _takeCollectionChanges() {
    final context = _collection;
    if (!mounted || context == null) return;
    final latest = _collections.getCollection(context.collection.id);
    if (identical(latest, context.collection)) return;
    final now = context.refreshedFrom(latest);
    final before = context.entry;
    final piece = now.entry;
    // Taken out of the collection, or the collection deleted: see
    // [_takeSetChanges].
    if (identical(now, context)) {
      _letGoOfTheEntry();
      return;
    }
    if (piece != null && piece.scoreId != _entryScoreId) {
      _letGoOfTheEntry(scannedAs: piece.scoreId);
      return;
    }
    setState(() {
      _collection = now;
      if (before != null && piece != null) {
        _takeReading(
          was: _Reading.ofPiece(entry: before),
          now: _Reading.ofPiece(entry: piece),
        );
      }
    });
  }

  /// Whether this player has changed how they read the score and that has not
  /// been kept yet: [_keepReading] is still waiting for them to stop, or the
  /// write is on its way.
  bool get _readingIsPending => _keeping != null || _savingReading > 0;

  /// How many writes of this player's reading have been started and have not
  /// come back yet.
  int _savingReading = 0;

  /// Puts on screen what an entry now says about how the score is read — the
  /// key the band plays it in, and this player's own reading of it — when that
  /// is not what it said a moment ago ([was]).
  ///
  /// It is worked out the way opening the page works it out. What the player
  /// has changed and not yet kept is the exception: that is theirs, and a sync
  /// arriving in the 400 ms before it is written is no reason to take it off
  /// them. So while something is pending, only what they have not touched —
  /// what is still on screen the way [was] put it — follows the entry; the
  /// rest stays, and is kept against the entry as it now stands.
  ///
  /// Called inside a `setState`.
  void _takeReading({required _Reading was, required _Reading now}) {
    final view = _view;
    if (view == null || was == now) return;
    final keepTouched = _readingIsPending;

    var next = view;
    if (!keepTouched || view.transposition == was.readAt) {
      next = next.withTransposition(now.readAt);
    }
    final hidden = view.hiddenPartIds;
    if (!keepTouched ||
        (hidden.length == was.hiddenParts.length &&
            was.hiddenParts.every(view.isHidden))) {
      next = next.withHiddenParts(now.hiddenParts);
    }
    _view = next;

    // The size is what the buttons set times what a pinch has added, and the
    // pinch is the sheet's to hold: it is the buttons' share that is moved, so
    // that the two together come out at the size the entry says.
    if (!keepTouched || _drawnAt(was.zoom)) {
      _space = _spaceFor(now.zoom) / _pinched;
    }
  }

  /// Plays the score for itself from here on, the way it opens when the entry
  /// it was opened from no longer plays it: as written, at the size it is
  /// written at, with nothing to keep a reading against.
  ///
  /// Whatever was waiting to be kept is dropped rather than written: it would
  /// be written into an entry that is now some other song.
  ///
  /// Except for one played from paper that has just been given its score
  /// ([scannedAs]): that is still the same song of the same set, and what the
  /// player wants is the score in its place — not to lose their place in the
  /// running order over somebody having scanned it.
  void _letGoOfTheEntry({String? scannedAs}) {
    final set = _set;
    final collection = _collection;
    if (_isPaper && scannedAs != null && (set != null || collection != null)) {
      final setId = set?.set.id;
      final collectionId = setId == null ? collection?.collection.id : null;
      final entryId = set?.entry.id ?? collection!.entryId;
      context.router.replace(
        scoreRoute(
          scannedAs,
          setId: setId,
          collectionId: collectionId,
          entryId: entryId,
          performing: widget.performing,
        ),
      );
      return;
    }
    _keeping?.cancel();
    _keeping = null;
    setState(() {
      _set = null;
      _collection = null;
      final view = _view;
      if (view != null) {
        _view = view.reset();
        _space = _writtenSpace / _pinched;
      }
    });
  }

  /// The score's details as a sync brings them in — its title, among others —
  /// and a newer upload of it, once a sync has fetched that onto the device.
  Future<void> _takeScoreChanges() async {
    if (!mounted) return;
    final scoreId = _scoreId;
    final score = scoreId == null ? null : _scores.getScore(scoreId);
    setState(() {});
    final fetched = score?.lastFetchedFileAt;
    if (_musicXml == null || fetched == null || fetched == _shownFetchedAt) {
      return;
    }
    final newer = _shownFetchedAt != null && fetched.isAfter(_shownFetchedAt!);
    _shownFetchedAt = fetched;
    if (!newer) return;
    final musicXml = (await GetIt.I<GetMusicXml>()(scoreId!)).valueOrNull;
    if (!mounted || musicXml == null || musicXml == _musicXml) return;
    _show(musicXml, keepingTheView: true);
  }

  Future<void> _load() async {
    if (_auth.value?.isScoreViewer != true) {
      setState(() => _loading = false);
      return;
    }
    if (_isNew) {
      setState(() => _loading = false);
      return;
    }
    if (_isPaper) {
      await _readSetContext();
      await _readCollectionContext();
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      await _readSetContext();
      await _readCollectionContext();
      final musicXml = (await GetIt.I<GetMusicXml>()(widget.scoreId)).orThrow();
      if (!mounted) return;

      if (musicXml == null) {
        setState(() {
          _loading = false;
          _failure =
              'This score is not on this device, and the server could'
              ' not be reached to fetch it.';
        });
        return;
      }

      _shownFetchedAt = _scores.getScore(widget.scoreId)?.lastFetchedFileAt;
      _show(musicXml);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failure = error;
        });
      }
    }

    // Bookkeeping, done once the music is on the stand and apart from putting
    // it there: failing to say when the score was last opened — its details
    // could not be fetched, say — must not take the score off the screen.
    if (_musicXml != null) {
      unawaited(Future(() => GetIt.I<MarkScoreViewed>()(widget.scoreId)));
    }
    unawaited(Future(() => GetIt.I<SyncScores>()()));
  }

  /// Reads a score and starts it off being looked at the way the set says it is
  /// played, or the way it was written when it is not being played from a set.
  ///
  /// [keepingTheView] is for a newer upload of the score arriving while it is
  /// on the stand: the player goes on reading it the way they were.
  void _show(String musicXml, {bool keepingTheView = false}) {
    final parts = readParts(parseMusicXml(musicXml)).toList();
    var view = ScoreView.forParts(partIds: [for (final part in parts) part.id]);
    final before = _view;
    if (keepingTheView && before != null) {
      view = view.withTransposition(before.transposition).withHiddenParts([
        for (final part in parts)
          if (before.isHidden(part.id)) part.id,
      ]);
      setState(() {
        _musicXml = musicXml;
        _parts = parts;
        _view = view;
      });
      return;
    }

    final entry = _set?.entry;
    if (entry != null) {
      // The score opens the way the band plays it and the way this player reads
      // it: the entry says the band is a tone down, the view says this player
      // reads that a fifth up, and what goes on screen is the two together —
      // at the size this player draws it, which is theirs alone.
      view = view
          .withTransposition(entry.combinedTransposition)
          .withHiddenParts(entry.view.hiddenParts);
      _space = _spaceFor(entry.view.zoom);
    }

    final piece = _collection?.entry;
    if (piece != null) {
      // The same out of a book, where how big it is drawn comes too: that is
      // this player's alone and is not added to anything.
      view = view
          .withTransposition(piece.combinedTransposition)
          .withHiddenParts(piece.view.hiddenParts);
      _space = _spaceFor(piece.view.zoom);
    }

    // Played from its details, it goes on being read the way it was being read
    // there — which is the entry's reading too when there is an entry, give or
    // take what was changed there in the moment before the stand was opened.
    final handover = widget.handover;
    if (handover != null) {
      view = view
          .withTransposition(handover.view.transposition)
          .withHiddenParts([
            for (final part in parts)
              if (handover.view.isHidden(part.id)) part.id,
          ]);
      _space = _spaceFor(handover.zoom);
    }

    setState(() {
      _musicXml = musicXml;
      _parts = parts;
      _view = view;
      _pinched = 1;
      _loading = false;
      _failure = null;
    });
  }

  /// Works out which set this score is being played from, if any.
  Future<void> _readSetContext() async {
    final setId = widget.setId;
    final entryId = widget.entryId;
    if (setId == null || entryId == null) {
      return;
    }

    // A link into a set can be followed on a device that has not synced since
    // it was shared: see [GetSet].
    final set = (await GetIt.I<GetSet>()(setId)).valueOrNull;
    if (set == null) return;

    final index = set.entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return;

    // The entry has to be an entry of this score. An entry can be written to
    // play a different score than it used to, and a link made before that would
    // otherwise hand this score the key and the hidden parts of a song it is
    // not. The score is what the page is of, so the set is what gives way.
    if (set.entries[index].scoreId != _entryScoreId) return;

    _set = _SetContext(set: set, index: index);
  }

  /// Works out which collection this score is being played from, if any.
  ///
  /// A collection this device has never heard of is asked for once — a link
  /// into one can be followed on a device that has not synced since it was
  /// shared — and, failing that, the score is played for itself.
  Future<void> _readCollectionContext() async {
    final collectionId = widget.collectionId;
    final entryId = widget.entryId;
    // Which entry it is has to have been said: a collection with nothing said
    // about which of its entries this is, is a score that happens to be in
    // one, and reading that as the first would play it in the wrong key.
    if (widget.setId != null || collectionId == null || entryId == null) {
      return;
    }

    final collection = (await GetIt.I<GetCollection>()(collectionId))
        .valueOrNull;
    if (collection == null) return;

    final entry = collection.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    // The entry has to be an entry of this score, for the same reason as in a
    // set: the score is what the page is of, so the collection gives way.
    if (entry == null || entry.scoreId != _entryScoreId) return;

    _collection = _CollectionContext(collection: collection, entryId: entryId);
  }

  /// What one staff space is worth for a view drawn at [zoom], held to what
  /// the zoom buttons go to.
  double _spaceFor(double zoom) =>
      (_writtenSpace * zoom).clamp(_minSpace, _maxSpace);

  /// How big the score is drawn now, as a view says it: where 1 is the size it
  /// is written at.
  double get _zoom => (_space * _pinched / _writtenSpace).clamp(
    ScoreViewSettings.minZoom,
    ScoreViewSettings.maxZoom,
  );

  /// Whether the score is on screen at the size a view with [zoom] draws it.
  bool _drawnAt(double zoom) =>
      (_spaceFor(zoom) - _space * _pinched).abs() < 0.01;

  void _changeView(ScoreView Function(ScoreView) change) {
    final view = _view;
    if (view == null) return;
    setState(() => _view = change(view));
    _keepReading();
  }

  void _zoomBy(double step) {
    setState(() => _space = (_space + step).clamp(_minSpace, _maxSpace));
    _keepReading();
  }

  /// Keeps how this player reads the score against the set or the collection
  /// it is played from, once they have stopped changing it for a moment: every
  /// tap of the key, and every step of a pinch, is not a write of its own.
  ///
  /// Kept rather than offered: a key moved for a gig and lost because nobody
  /// pressed save is found out at the next gig, in front of the band.
  void _keepReading() {
    if (_set == null && _collection == null) return;
    _keeping?.cancel();
    _keeping = Timer(const Duration(milliseconds: 400), _keepWhatIsWaiting);
  }

  /// Keeps now what [_keepReading] was waiting to — before the page is left for
  /// the next song, closed, or put in the background.
  void _keepWhatIsWaiting() {
    final waiting = _keeping;
    _keeping = null;
    if (waiting == null) return;
    waiting.cancel();
    if (!_canSaveView) return;
    if (_set != null) {
      unawaited(_saveViewToSet());
    } else if (_collection != null) {
      unawaited(_saveViewToCollection());
    }
  }

  // -------------------------------------------------------------------------
  // PLAYING FROM A SET
  // -------------------------------------------------------------------------

  /// Whether the way the score is on screen is the way the set says it is
  /// played and this player reads it — the size it is drawn at included.
  /// While it is, there is nothing to save.
  bool get _viewMatchesEntry {
    final entry = _set?.entry;
    final view = _view;
    if (entry == null || view == null) return true;

    final hidden = entry.view.hiddenParts;
    return _readingOffset(
              band: entry.transposition,
              saved: entry.view.transposition,
              savedReadAt: entry.combinedTransposition,
              onScreen: view.transposition,
            ) ==
            entry.view.transposition &&
        hidden.length == view.hiddenPartIds.length &&
        hidden.every(view.isHidden) &&
        _drawnAt(entry.view.zoom);
  }

  /// Writes the way this player is looking at the score into the set, so that
  /// it opens that way the next time they play it.
  ///
  /// It is their own reading of it and nobody else's: the saxophone player
  /// saving their key changes nothing for the pianist. Neither the score nor
  /// the set is touched — what the band does is the owner's to say, and what is
  /// stored here is only how far this player reads it from there, which is what
  /// is on screen less the key the band plays it in.
  Future<void> _saveViewToSet() async {
    final context = _set;
    final view = _view;
    if (context == null || view == null) return;

    _savingReading++;
    try {
      final saved = (await GetIt.I<SaveSetEntryView>()(
        SaveSetEntryViewParams(
          setId: context.set.id,
          entryId: context.entry.id,
          transposition: _readingOffset(
            band: context.entry.transposition,
            saved: context.entry.view.transposition,
            savedReadAt: context.entry.combinedTransposition,
            onScreen: view.transposition,
          ),
          hiddenParts: [...view.hiddenPartIds],
          zoom: _zoom,
        ),
      )).orThrow();
      // Where the entry comes in the set is read again rather than kept: a sync
      // can have reordered the gig while this was being written, and taking the
      // place it used to be at would put somebody else's song on the screen.
      final moved = saved.entries.indexWhere(
        (entry) => entry.id == context.entry.id,
      );
      if (!mounted) return;
      // Nor is the entry taken back once it has been let go of: a sync that
      // wrote it to play another score while this was on its way has already
      // said this page is not that entry's any more.
      if (_set == null ||
          (moved >= 0 && saved.entries[moved].scoreId != _entryScoreId)) {
        _letGoOfTheEntry();
        return;
      }
      setState(() {
        _set = moved < 0 ? null : _SetContext(set: saved, index: moved);
      });
      _say('Saved as how you read it.', briefly: true);
    } catch (error) {
      if (!mounted) return;
      _say('How you read this could not be saved: $error');
    } finally {
      _savingReading--;
    }
  }

  // -------------------------------------------------------------------------
  // PLAYING FROM A COLLECTION
  // -------------------------------------------------------------------------

  /// Whether the way the score is on screen is the way the collection says it
  /// is played and this player reads it — the size it is drawn at included.
  /// While it is, there is nothing to save.
  bool get _viewMatchesCollectionEntry {
    final entry = _collection?.entry;
    final view = _view;
    if (entry == null || view == null) return true;

    final hidden = entry.view.hiddenParts;
    return _readingOffset(
              band: entry.transposition,
              saved: entry.view.transposition,
              savedReadAt: entry.combinedTransposition,
              onScreen: view.transposition,
            ) ==
            entry.view.transposition &&
        hidden.length == view.hiddenPartIds.length &&
        hidden.every(view.isHidden) &&
        _drawnAt(entry.view.zoom);
  }

  /// Whether there is a reading of this score to keep, against whichever of a
  /// set or a collection it is being played from.
  bool get _canSaveView =>
      (_set != null && !_viewMatchesEntry) ||
      (_collection != null && !_viewMatchesCollectionEntry);

  /// Writes the way this player is looking at the score into the collection,
  /// so that it opens that way the next time they play it out of the book.
  ///
  /// As for a set, it is their own reading and nobody else's, and it is stored
  /// as how far they read it from the key the group plays it in. How big it is
  /// drawn goes with it, since that is theirs too.
  Future<void> _saveViewToCollection() async {
    final context = _collection;
    final view = _view;
    final entry = context?.entry;
    if (context == null || view == null || entry == null) return;

    _savingReading++;
    try {
      final saved = (await GetIt.I<SaveCollectionEntryView>()(
        SaveCollectionEntryViewParams(
          collectionId: context.collection.id,
          entryId: entry.id,
          transposition: _readingOffset(
            band: entry.transposition,
            saved: entry.view.transposition,
            savedReadAt: entry.combinedTransposition,
            onScreen: view.transposition,
          ),
          hiddenParts: [...view.hiddenPartIds],
          zoom: _zoom,
        ),
      )).orThrow();
      if (!mounted) return;
      final piece = saved.entries
          .where((piece) => piece.id == entry.id)
          .firstOrNull;
      // See the same in [_saveViewToSet].
      if (_collection == null ||
          (piece != null && piece.scoreId != _entryScoreId)) {
        _letGoOfTheEntry();
        return;
      }
      setState(() {
        _collection = piece != null
            ? _CollectionContext(collection: saved, entryId: entry.id)
            : null;
      });
      _say('Saved as how you read it.', briefly: true);
    } catch (error) {
      if (!mounted) return;
      _say('How you read this could not be saved: $error');
    } finally {
      _savingReading--;
    }
  }

  // -------------------------------------------------------------------------
  // TAKING A SCORE AWAY, AND PUTTING ONE THERE
  // -------------------------------------------------------------------------

  /// Writes the score out as it was uploaded: the file an editor corrects and
  /// puts back with "Replace this score", which is why it is the one the
  /// download button gives without asking. How it is being looked at is never
  /// in it.
  Future<void> _download() async {
    final musicXml = _musicXml;
    final scoreId = _scoreId;
    if (musicXml == null || scoreId == null) {
      _say(
        'This score cannot be downloaded because it has not been saved yet.',
      );
      return;
    }

    await _writeOut(musicXml, filename: '$scoreId.musicxml');
  }

  /// Writes the score out the way it is being looked at: the parts that are
  /// off screen are not in it, and it is in the key it is being read in.
  ///
  /// It is not the score, and it is named so it cannot be taken for it: a copy
  /// a tone up with the piano taken out, corrected and uploaded over the real
  /// one, is the real one lost for the whole band.
  Future<void> _downloadAsOnScreen() async {
    final musicXml = _musicXml;
    final scoreId = _scoreId;
    if (musicXml == null || scoreId == null) {
      _say(
        'This score cannot be downloaded because it has not been saved yet.',
      );
      return;
    }

    final String asOnScreen;
    try {
      asOnScreen = musicXmlForView(musicXml, _view);
    } catch (error) {
      _say('This score could not be written out: $error');
      return;
    }
    final title = _scores.getScore(scoreId)?.title.trim() ?? '';
    // A title is somebody's words, and some of what they may be is not
    // allowed in a file name on one system or another.
    final name = title.isEmpty
        ? scoreId
        : title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    await _writeOut(asOnScreen, filename: '$name (as on screen).musicxml');
  }

  Future<void> _writeOut(String musicXml, {required String filename}) async {
    try {
      await saveFile(
        filename: filename,
        bytes: utf8.encode(musicXml),
        mimeType: 'application/vnd.recordare.musicxml',
      );
    } catch (error) {
      _say('This score could not be written out: $error');
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['musicxml', 'xml'],
    );
    final file = picked.firstOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();

    // Read before it is sent: a file that cannot be read is a file the band
    // cannot play, and finding that out after it is on the server is finding it
    // out too late. That goes for the bytes as much as for the XML: a file that
    // is not UTF-8 is refused rather than read with its accents replaced, which
    // would upload a score whose titles and lyrics are quietly wrong.
    final String musicXml;
    try {
      musicXml = utf8.decode(bytes);
      parseMusicXml(musicXml);
    } catch (error) {
      _say('That file could not be read as a score: $error');
      return;
    }

    if (!mounted) return;
    final scoreId = _scoreId ?? _newScoreId;

    try {
      (await GetIt.I<UploadScore>()(
        (scoreId, musicXml),
      )).orThrow();
      if (!mounted) return;
      if (_isNew && _auth.value?.isScoreViewer == true) {
        // Its own address would only say this account may not read it. The
        // page stays, for the next file.
        _say('Uploaded.', briefly: true);
        return;
      }
      if (_isNew) {
        // Uploaded, it is a score like any other and is at its own address, so
        // that reloading it or keeping it opens this score rather than another
        // empty upload page. The file is on this device by now, so the page at
        // that address opens straight onto it.
        unawaited(Future(() => GetIt.I<SyncScores>()()));
        context.router.replace(ScoreRoute(scoreId: scoreId));
        return;
      }
      setState(() => _scoreId = scoreId);
      _show(musicXml);
      await GetIt.I<SyncScores>()();
    } catch (error) {
      if (mounted) _say('That score could not be uploaded: $error');
    }
  }

  // -------------------------------------------------------------------------
  // PLAYING FROM IT
  // -------------------------------------------------------------------------

  /// Puts the score on the whole screen, read the way it is being read here.
  ///
  /// What was waiting to be kept is kept first: the stand keeps its own
  /// reading against the same entry, and the two must not cross.
  void _perform() {
    _keepWhatIsWaiting();
    final view = _view;
    context.router.push(
      PerformScoreRoute(
        scoreId: widget.scoreId,
        setId: _set?.set.id,
        collectionId: _set == null ? _collection?.collection.id : null,
        entryId: _set?.entry.id ?? _collection?.entryId,
        handover: view == null
            ? null
            : ScoreReadingHandover(
                view: view,
                zoom: _zoom,
                onReturn: _takeBackFromTheStand,
              ),
      ),
    );
  }

  /// Takes on how the score was being read when the stand was closed. Not kept
  /// again: the stand kept it already, against whatever it is played from.
  ///
  /// The stand calls this while it is being taken down, which is no moment to
  /// rebuild anything in; so it waits for that to be over.
  void _takeBackFromTheStand(ScoreView view, double zoom) {
    scheduleMicrotask(() {
      final now = _view;
      if (!mounted || now == null) return;
      setState(() {
        _view = now.withTransposition(view.transposition).withHiddenParts([
          for (final part in _parts)
            if (view.isHidden(part.id)) part.id,
        ]);
        _space = _spaceFor(zoom) / _pinched;
      });
    });
  }

  /// The key and the parts, over the stand: the score stays where it is under
  /// it, and changes as they are changed.
  Future<void> _openReadingDialog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final view = _view;
        return AlertDialog(
          title: const Text('How you read it'),
          content: view == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  child: _ViewSettings(
                    view: view,
                    parts: _parts,
                    keptAsYourReading: _set != null || _collection != null,
                    onChange: (change) {
                      _changeView(change);
                      setDialogState(() {});
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    ),
  );

  void _say(String message, {bool briefly = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: briefly
              ? const Duration(milliseconds: 2500)
              : const Duration(seconds: 4),
        ),
      );
  }

  Widget _sheet() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final failure = _failure;
    if (failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('$failure', textAlign: TextAlign.center),
        ),
      );
    }
    final musicXml = _musicXml;
    if (_isPaper) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _set == null && _collection == null
                ? 'This song is no longer in there.'
                : _set != null
                ? 'This one is played from paper.'
                : 'This one has not been scanned yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }
    if (musicXml == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _isNew
                ? 'Choose a MusicXML file to upload.'
                : 'There is nothing to show.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // The page is lit the way this device has been told to light it, and it
    // keeps up with the slider while it is being dragged. What is passed is a
    // whole palette rather than a colour or two: ink and paper only look right
    // if whoever decides one decides the other.
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final look = _settings.pageLook(Theme.of(context).brightness);
        return ScoreSheet(
          musicXml: musicXml,
          view: _view,
          space: _space,
          onPinched: (pinched) {
            setState(() => _pinched = pinched);
            _keepReading();
          },
          palette: SheetPalette.lamp(
            brightness: look.brightness,
            warmth: look.warmth,
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => _page(context),
    );
  }

  Widget _page(BuildContext context) {
    final mayView = _auth.value?.isScoreViewer == true;
    final score = _scoreId == null ? null : _scores.getScore(_scoreId!);
    final paperName =
        (_set?.entry.description ?? _collection?.entry?.description ?? '')
            .trim();
    final title = _isPaper
        ? (paperName.isEmpty ? 'Played from paper' : paperName)
        : score?.title ?? (_isNew ? 'New score' : 'Score');

    // Uploading takes being an editor, not a reader: the server lets a score
    // be put by somebody who may not read it back, and an account kept for
    // filling the library is exactly that.
    final mayUpload = _isNew && _auth.value?.isScoreEditor == true;
    if (!mayView && !mayUpload) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Scores are for score viewers.')),
      );
    }
    return widget.performing ? _stand(title) : _details(title, score);
  }

  /// The way through the set or the collection this is played from, if it is.
  ///
  /// The collection is read as it is now rather than as it was when the page
  /// opened: the titles the way through it is sorted by arrive with the
  /// scores, after the page has opened, and a sync can bring in pieces
  /// somebody else put into the book. Which is why whatever draws this
  /// listens to both.
  _WayThrough? _wayThrough() {
    final set = _set;
    if (set != null) {
      return _WayThrough.ofSet(context: set, performing: widget.performing);
    }
    final collection = _collection;
    // A collection is a book and not a running order, so its details have
    // no way through it: the piece is looked up, not played after the last.
    // On the stand the pieces either side are still a tap away.
    if (collection != null && widget.performing) {
      return _WayThrough.ofCollection(
        collection.refreshedFrom(
          _collections.getCollection(collection.collection.id),
        ),
        titleOf: (scoreId) => _scores.getScore(scoreId)?.title,
        performing: widget.performing,
      );
    }
    return null;
  }

  /// Opens the one before or after this one, in place of this one.
  void _go(PageRouteInfo route) {
    _keepWhatIsWaiting();
    context.router.replace(route);
  }

  /// What a bar of the way through is drawn from changing.
  Listenable get _wayChanges => Listenable.merge([_collections, _scores]);

  /// The score on the whole screen, with nothing over it but the way back,
  /// its size, and how it is read.
  ///
  /// The size is right there, since it is what is changed most while playing
  /// — and a pinch does it as well. The key and the parts are a tap further
  /// away, in a dialog over the music. Downloading and uploading are not here
  /// at all: nobody does either from a music stand, and a button that does
  /// is a button that gets pressed by accident between two songs.
  ///
  /// Played from a set or a collection, the way through it is in the same bar
  /// rather than a second one under it: a bar is a staff's worth of height,
  /// and on a stand that is a staff of music not shown. The title says which
  /// set it is and where this song comes in it, and opens the set.
  Widget _stand(String title) {
    return ListenableBuilder(
      listenable: _wayChanges,
      builder: (context, _) => _standFor(_wayThrough(), title),
    );
  }

  Widget _standFor(_WayThrough? way, String title) {
    final hasMusic = _musicXml != null;
    final theme = Theme.of(context);
    final previous = way?.previous;
    final next = way?.next;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: way == null ? 48 : 56,
        titleSpacing: 0,
        // The way through the set is in the middle, the way it was in a bar of
        // its own: the song before, which song this is, and the song after.
        // Back stays where back is, and the size and the key on the other side.
        centerTitle: way != null,
        title: way == null
            ? Text(title, overflow: TextOverflow.ellipsis)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PreviousScoreButton(
                    onPressed: previous == null ? null : () => _go(previous),
                  ),
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.router.push(way.route),
                      child: Tooltip(
                        message: way.isSet
                            ? 'Open the set'
                            : 'Open the collection',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, overflow: TextOverflow.ellipsis),
                              Text(
                                [
                                  '${way.position} of ${way.count}',
                                  way.title,
                                  if (way.note.isNotEmpty) way.note,
                                ].join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  NextScoreButton(
                    onPressed: next == null ? null : () => _go(next),
                  ),
                ],
              ),
        actions: [
          if (hasMusic) ...[
            ZoomOutButton(onPressed: () => _zoomBy(-0.8)),
            ZoomInButton(onPressed: () => _zoomBy(0.8)),
            if (_view != null)
              IconButton(
                tooltip: 'How you read it',
                icon: const Icon(Icons.tune),
                onPressed: _openReadingDialog,
              ),
          ],
        ],
      ),
      body: _sheet(),
    );
  }

  /// What is known about the score and how it is read, beside a look at it —
  /// or above one, on a screen that is taller than it is wide.
  Widget _details(String title, Score? score) {
    final mayEdit = _auth.value?.isScoreEditor == true;
    final hasMusic = _musicXml != null;

    final appBar = AppBar(title: Text(title));

    // A score that is about to be uploaded has nothing to say about itself
    // yet, and nothing to play: there is only the file to choose.
    if (_isNew) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a MusicXML file to upload.'),
              if (mayEdit) ...[
                const SizedBox(height: 16),
                UploadScoreButton(replacing: false, onPressed: _pickAndUpload),
              ],
            ],
          ),
        ),
      );
    }

    // What is done with the file itself, beside what is known about it.
    final files = [
      if (hasMusic)
        DownloadScoreButton(
          onDownloadAsWritten: _download,
          // Only offered once there is a difference to offer: a score nobody
          // has changed the look of is the file it was uploaded as, and two
          // ways of downloading the same bytes is one too many.
          onDownloadAsOnScreen: _view == null || _view!.isPristine
              ? null
              : _downloadAsOnScreen,
        ),
      if (mayEdit && !_isPaper)
        UploadScoreButton(
          replacing: _scoreId != null,
          onPressed: _pickAndUpload,
        ),
    ];

    final about = <Widget>[
      FilledButton.icon(
        onPressed: _loading || _failure != null ? null : _perform,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Perform'),
      ),
      if (score != null) ...[
        const SizedBox(height: 16),
        _ScoreFacts(score: score),
      ],
      if (_view != null) ...[
        const SizedBox(height: 16),
        Text('How you read it', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _ViewSettings(
          view: _view!,
          parts: _parts,
          onChange: _changeView,
          keptAsYourReading: _set != null || _collection != null,
        ),
      ],
      if (files.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('The score file', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: files),
      ],
    ];

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _wayChanges,
            builder: (context, _) => switch (_wayThrough()) {
              final way? => _WayBar(way: way, go: _go),
              null => const SizedBox.shrink(),
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Side by side when the screen is wider than it is tall: a
                // landscape tablet has room for the facts and a page of the
                // score both, and a phone held upright has room for neither
                // beside the other.
                if (constraints.maxWidth > constraints.maxHeight) {
                  final panel = (constraints.maxWidth * 0.38).clamp(
                    280.0,
                    440.0,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: panel,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: about,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _sheet()),
                    ],
                  );
                }
                // Upright, the score is at the bottom, and the facts above it
                // give way to it rather than pushing it off the screen: they
                // scroll, in at most a little over half of it.
                return Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.55,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: about,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _sheet()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Which set this score is being played from, and where in it.
class const _SetContext({
  required final ScoreSet set,
  required final int index,
}) {
  SetEntry get entry => set.entries[index];
}

/// The way through the set or the collection a score is played from: where
/// this one comes in it, and what comes either side.
class const _WayThrough({
  required final bool isSet,

  /// What the set or the collection is called, and where it is.
  required final String title,
  required final PageRouteInfo route,

  /// Where this one comes in it, counted from one, and how many there are.
  required final int position,
  required final int count,

  /// Where the ones either side are, or null at either end.
  required final PageRouteInfo? previous,
  required final PageRouteInfo? next,

  /// What the set or the collection says next to this one.
  required final String note,
}) {
  /// The way through a set, in its running order.
  ///
  /// The next song either way, one played from paper included. That is not
  /// stepped over: it is what the band is playing, and a player looking at the
  /// song after it is lost when the band starts that one.
  factory _WayThrough.ofSet({
    required _SetContext context,
    required bool performing,
  }) {
    final set = context.set;
    PageRouteInfo? nearest(int step) {
      final index = context.index + step;
      if (index < 0 || index >= set.entries.length) return null;
      final entry = set.entries[index];
      final scoreId = entry.scoreId;
      return scoreId == null
          ? paperRoute(setId: set.id, entryId: entry.id)
          : scoreRoute(
              scoreId,
              setId: set.id,
              entryId: entry.id,
              performing: performing,
            );
    }

    return _WayThrough(
      isSet: true,
      title: set.displayTitle,
      route: SetDetailRoute(setId: set.id),
      position: context.index + 1,
      count: set.entries.length,
      previous: nearest(-1),
      next: nearest(1),
      note: context.entry.description.trim(),
    );
  }

  /// The way through a collection, by title — one that has yet to be scanned
  /// included, as in a set. Null when the piece is no longer in it.
  static _WayThrough? ofCollection(
    _CollectionContext context, {
    required String? Function(String scoreId) titleOf,
    required bool performing,
  }) {
    final collection = context.collection;
    final entries = CollectionEntry.sortByTitle(collection.entries, titleOf);
    final index = entries.indexWhere((entry) => entry.id == context.entryId);
    if (index < 0) return null;

    PageRouteInfo? nearest(int step) {
      final at = index + step;
      if (at < 0 || at >= entries.length) return null;
      final candidate = entries[at];
      final scoreId = candidate.scoreId;
      return scoreId == null
          ? paperRoute(collectionId: collection.id, entryId: candidate.id)
          : scoreRoute(
              scoreId,
              collectionId: collection.id,
              entryId: candidate.id,
              performing: performing,
            );
    }

    return _WayThrough(
      isSet: false,
      title: collection.displayTitle,
      route: CollectionDetailRoute(collectionId: collection.id),
      position: index + 1,
      count: entries.length,
      previous: nearest(-1),
      next: nearest(1),
      note: entries[index].description.trim(),
    );
  }
}

/// The way through the set or the collection, as a bar of its own under the
/// details of a score.
class const _WayBar({
  required final _WayThrough way,

  /// Opens the page at a route in place of this one.
  required final void Function(PageRouteInfo route) go,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = way.previous;
    final next = way.next;
    void open() => context.router.push(way.route);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            PreviousScoreButton(
              onPressed: previous == null ? null : () => go(previous),
            ),
            // Flexible, so that a long title gives way rather than pushing the
            // way to the next one off the edge of a phone.
            Flexible(
              child: way.isSet
                  ? OpenSetButton(title: way.title, onPressed: open)
                  : OpenCollectionButton(title: way.title, onPressed: open),
            ),
            Text(
              '${way.position} of ${way.count}',
              style: theme.textTheme.labelMedium,
            ),
            NextScoreButton(
              onPressed: next == null ? null : () => go(next),
            ),
            if (way.note.isNotEmpty)
              Expanded(
                child: Text(
                  way.note,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Which collection this score is being played from, and which of its pieces
/// it is.
///
/// Where it comes in the collection is not kept: a collection has no order, so
/// the way through it is by title, and the titles are in the scores — which
/// can arrive after the page has opened. So it is worked out each time the bar
/// is drawn, and "3 of 21" means the third one down the page somebody was just
/// looking at.
class const _CollectionContext({
  required final Collection collection,
  required final String entryId,
}) {
  CollectionEntry? get entry => collection.entries
      .where((candidate) => candidate.id == entryId)
      .firstOrNull;

  /// The same piece of the collection as it now stands, or of the collection
  /// as it was when there is no longer one on this device to read.
  _CollectionContext refreshedFrom(Collection? now) {
    if (now == null || !now.entries.any((entry) => entry.id == entryId)) {
      return this;
    }
    return _CollectionContext(collection: now, entryId: entryId);
  }
}

/// What is known about a score: who wrote it, what plays it, and what it is
/// filed under.
class const _ScoreFacts({
  required final Score score,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final work = score.work;
    final movement = score.movement;
    final rows = <(String, String)>[
      if (score.creators.composers.isNotEmpty)
        ('Composed by', score.creators.composers.join(', ')),
      if (score.creators.lyricists.isNotEmpty)
        ('Words by', score.creators.lyricists.join(', ')),
      if ((work?.number ?? '').trim().isNotEmpty) ('Number', work!.number!),
      // A movement is only worth saying when it is not already the title.
      if ((movement?.title ?? '').trim().isNotEmpty &&
          movement!.title!.trim() != score.title)
        ('Movement', movement.title!.trim()),
      if (score.instruments.isNotEmpty)
        ('Played by', score.instruments.map(instrumentName).join(', ')),
      if (score.languages.isNotEmpty) ('Sung in', score.languages.join(', ')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        if (score.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in score.tags)
                Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
      ],
    );
  }
}

/// How the score is read: the key, and which parts are on screen. On the
/// details page, and in the dialog over the stand.
class const _ViewSettings({
  required final ScoreView view,
  required final List<ScorePartRef> parts,
  required final void Function(ScoreView Function(ScoreView)) onChange,

  /// Whether what is changed here is kept as this player's reading of the
  /// song, which it is when it is played from a set or a collection.
  required final bool keptAsYourReading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final semitones = view.transposition;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Transpose'),
            const Spacer(),
            TransposeDownButton(
              onPressed: semitones > ScoreViewSettings.minTransposition
                  ? () => onChange(
                      (view) => view.withTransposition(semitones - 1),
                    )
                  : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${semitones > 0 ? '+' : ''}$semitones',
                textAlign: TextAlign.center,
              ),
            ),
            TransposeUpButton(
              onPressed: semitones < ScoreViewSettings.maxTransposition
                  ? () => onChange(
                      (view) => view.withTransposition(semitones + 1),
                    )
                  : null,
            ),
          ],
        ),
        if (parts.length > 1) ...[
          const SizedBox(height: 8),
          const Text('Instruments on screen'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final part in parts)
                PartVisibilityChip(
                  name: part.name,
                  visible: !view.isHidden(part.id),
                  onSelected: (visible) => onChange(
                    (view) => view.withPartVisible(part.id, visible),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ShowAsWrittenButton(
              onPressed: view.isPristine
                  ? null
                  : () => onChange((view) => view.reset()),
            ),
            if (keptAsYourReading)
              Tooltip(
                message:
                    "Only you see this. What the band plays is the"
                    " owner's to say.",
                child: Text(
                  'Kept as how you read it',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// What an entry of a set or a collection says about how its score is read:
/// the key it is on screen in, the parts that are not, and how big it is
/// drawn.
///
/// Two of them are the same when the band's key and the player's own offset
/// are both the same, not only what they add up to: the one saved offset is
/// what [_readingOffset] counts from, and a change to it with the sum held at
/// the octave is still a change to how the player's next save is worked out.
class _Reading._({
  required final int band,
  required ScoreViewSettings view,
  required final int readAt,
}) {
  _Reading.ofSong({
    required SetEntry entry,
  }) : this._(
         band: entry.transposition,
         view: entry.view,
         readAt: entry.combinedTransposition,
       );

  _Reading.ofPiece({
    required CollectionEntry entry,
  }) : this._(
         band: entry.transposition,
         view: entry.view,
         readAt: entry.combinedTransposition,
       );

  this
    : saved = view.transposition,
      hiddenParts = view.hiddenParts,
      zoom = view.zoom;

  final int saved;
  final List<String> hiddenParts;
  final double zoom;

  @override
  bool operator ==(Object other) =>
      other is _Reading &&
      other.band == band &&
      other.saved == saved &&
      other.readAt == readAt &&
      other.zoom == zoom &&
      other.hiddenParts.length == hiddenParts.length &&
      other.hiddenParts.every(hiddenParts.contains);

  @override
  int get hashCode => Object.hash(
    band,
    saved,
    readAt,
    zoom,
    Object.hashAllUnordered(hiddenParts),
  );
}

/// How far from the key the band plays it in ([band]) a player reads a score,
/// as saving what is on screen would store it.
///
/// What is on screen is the band's key and the player's own offset added and
/// then held to an octave either way, so it cannot always be taken apart
/// again: the band up ten and the player up five shows as up twelve, and
/// twelve less ten is not five. So while the screen is still where the saved
/// reading put it ([savedReadAt]), the offset that was [saved] is kept as it
/// was, and hiding a part does not quietly turn up five into up two. Only a
/// key the player actually moved to is worked out again, and held to the
/// octave the API takes, so that a save button compared against this turns
/// off once there is nothing different left to save.
int _readingOffset({
  required int band,
  required int saved,
  required int savedReadAt,
  required int onScreen,
}) {
  if (onScreen == savedReadAt) return saved;
  return (onScreen - band).clamp(
    ScoreViewSettings.minTransposition,
    ScoreViewSettings.maxTransposition,
  );
}

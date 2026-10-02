import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:score/app.dart';
import 'package:score/background.dart';
import 'package:score/features/collections/models.dart'
    show Collection, CollectionEntry, entriesByTitle, maxZoom, minZoom;
import 'package:score/features/collections/repository.dart';
import 'package:score/features/files/file_saver.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/musicxml_view.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/repository.dart';
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
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/repository.dart';
import 'package:score/routes.dart';
import 'package:uuid/uuid.dart';

/// One score: what is known about it with a look at it, or — [performing] —
/// the whole screen given over to playing from it.
///
/// The two are one page in two ways rather than two pages, because everything
/// about how the score is read — and keeping that against the set or the
/// collection it is played from — is the same in both. What the details have
/// and the stand does not is the reason to look anything up: who wrote it,
/// what plays it, the download and the upload. What the stand has is the
/// score, as big as it will go, and only what is changed while playing.
///
/// How it is being looked at — the key it is read in, which parts are on screen,
/// how big it is drawn — never changes the document, which is what the editor
/// uploaded and stays that way. Played from a set or a collection, it is kept
/// as this player's reading of that entry (see [_ScoreDetailPageState._keepReading]):
/// theirs alone, and saved as they change it, the way the app it replaces did.
class ScoreDetailPage extends StatefulWidget {
  const ScoreDetailPage({
    super.key,
    required this.scoreId,
    this.setId,
    this.collectionId,
    this.entryId,
    this.performing = false,
    this.handover,
  });

  /// `new` for a score that is about to be uploaded.
  final String scoreId;

  /// Whether the score is on the whole screen, to be played from.
  final bool performing;

  /// How the details page it was opened from had the score, when it was
  /// opened from one: see [ScoreReadingHandover].
  final ScoreReadingHandover? handover;

  final String? setId;

  /// The collection this score is being played from, when it is being played
  /// from one rather than from a set.
  ///
  /// A set is a gig and a collection is a book, but what a score is opened as
  /// is the same thing in both — a piece, in the key the others play it in,
  /// read the way this player reads it, with the rest of the list either side
  /// of it. What differs is which repository a view is written to, and what
  /// order the list is in.
  final String? collectionId;

  /// Which entry of the set or the collection this is.
  final String? entryId;

  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

/// How a score is being read on its details page, handed to the stand it is
/// played from there — and back, once the playing is done.
///
/// A key moved on a score played for itself is kept nowhere but on the page
/// it was moved on: there is no entry of a set to write it into. Without this
/// the stand would open as written, and the details would not know what was
/// changed while playing.
class ScoreReadingHandover {
  const ScoreReadingHandover({
    required this.view,
    required this.zoom,
    required this.onReturn,
  });

  final ScoreView view;

  /// How big it is drawn, as a view says it: 1 is the size it is written at.
  final double zoom;

  /// Called with how the stand had it, as the stand is closed.
  final void Function(ScoreView view, double zoom) onReturn;
}

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  /// How many stands are open. Going on to the next song puts up its stand
  /// before the last one is taken down, and the screen stays the stand's
  /// until the last of them is.
  static int _stands = 0;

  static const _uuid = Uuid();
  List<ScorePartRef> _parts = const [];

  /// The score as it was uploaded. Transposing and hiding parts never touch it,
  /// so this stays what is downloaded and re-uploaded.
  String? _musicXml;

  String? _scoreId;

  /// The id a new score is uploaded under, picked once per page rather than
  /// per attempt. An upload can reach the server and still come back as failed
  /// (the answer lost on the way, or the copy on this device not written), and
  /// the server only knows a score by its id: trying again under a new one
  /// would put the score there twice.
  late final String _newScoreId = _uuid.v4();
  ScoreView? _view;

  bool _loading = true;
  Object? _failure;

  /// What one staff space is worth on screen when the score is drawn the size
  /// it is written at — which is what a zoom of 1 means in a view.
  static const _writtenSpace = 7.5;

  /// As far as a score may be drawn either way: the sizes a view can say,
  /// which the buttons go to as well. Any narrower, and a size saved by
  /// another device would be drawn smaller than it says, and saved back so.
  static const _minSpace = _writtenSpace * minZoom;
  static const _maxSpace = _writtenSpace * maxZoom;

  /// What one staff space is worth on screen — the zoom the buttons set.
  double _space = _writtenSpace;

  /// How much a pinch has made the score bigger or smaller than [_space] on
  /// top of that. What is on screen is the two together, and that is what is
  /// saved as how big this player reads it.
  double _pinched = 1;

  /// The set this score is being played from, when it is being played from one.
  _SetContext? _set;

  /// The collection this score is being played from, when it is being played
  /// from one.
  _CollectionContext? _collection;

  bool get _isNew => widget.scoreId == 'new';

  /// Whether this is an entry of a set or a collection that is played from
  /// paper: there is no score to draw, and the page is there to say which song
  /// it is and to go on to the next.
  bool get _isPaper => widget.scoreId == ScoreDetailRoute.paper;

  /// The score the entry this is opened from has to be of: none, for one on
  /// paper.
  String? get _entryScoreId => _isPaper ? null : widget.scoreId;

  /// Held rather than looked up: the page saves what is waiting on its way out,
  /// when there is no looking anything up any more.
  late final App _app;
  late final SetsRepository _sets;
  late final CollectionsRepository _collections;
  late final ScoresRepository _scores;

  /// Waits for the player to stop changing how they read the score before it
  /// is kept: see [_keepReading].
  Timer? _keeping;

  /// What the document on screen was fetched as, so that a sync that fetches a
  /// newer upload of it is noticed: see [_takeScoreChanges].
  DateTime? _shownFetchedAt;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _scoreId = _isNew || _isPaper ? null : widget.scoreId;
    _app = AppScope.read(context);
    _sets = _app.sets..addListener(_takeSetChanges);
    _collections = _app.collections..addListener(_takeCollectionChanges);
    _scores = _app.scores..addListener(_takeScoreChanges);
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
    final index =
        now?.entries.indexWhere((entry) => entry.id == context.entry.id) ?? -1;
    if (now == null || index < 0 || identical(now, context.set)) return;
    final entry = now.entries[index];
    // The same check as when the page was opened: an entry written to play a
    // different score while this one is open is not this score's any more,
    // and neither are its key and its parts.
    if (entry.scoreId != _entryScoreId) {
      _letGoOfTheEntry();
      return;
    }
    setState(() {
      _set = _SetContext(set: now, index: index);
      _takeReading(
        was: _Reading.ofSong(context.entry),
        now: _Reading.ofSong(entry),
      );
    });
  }

  /// The same as [_takeSetChanges], for a collection.
  void _takeCollectionChanges() {
    final context = _collection;
    if (!mounted || context == null) return;
    final now = context.refreshedFrom(
      _collections.getCollection(context.collection.id),
    );
    if (identical(now.collection, context.collection)) return;
    final before = context.entry;
    final piece = now.entry;
    if (piece != null && piece.scoreId != _entryScoreId) {
      _letGoOfTheEntry();
      return;
    }
    setState(() {
      _collection = now;
      if (before != null && piece != null) {
        _takeReading(
          was: _Reading.ofPiece(before),
          now: _Reading.ofPiece(piece),
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
  void _letGoOfTheEntry() {
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
    final musicXml = await _scores.getMusicXml(scoreId!);
    if (!mounted || musicXml == null || musicXml == _musicXml) return;
    _show(musicXml, keepingTheView: true);
  }

  Future<void> _load() async {
    final app = _app;

    if (app.user?.isScoreViewer != true) {
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
      final musicXml = await app.scores.getMusicXml(widget.scoreId);
      if (!mounted) return;

      if (musicXml == null) {
        setState(() {
          _loading = false;
          _failure = 'This score is not on this device, and the server could'
              ' not be reached to fetch it.';
        });
        return;
      }

      _shownFetchedAt = app.scores.getScore(widget.scoreId)?.lastFetchedFileAt;
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
      inTheBackground(app.scores.markViewed(widget.scoreId));
    }
    inTheBackground(app.updateScores());
  }

  /// Reads a score and starts it off being looked at the way the set says it is
  /// played, or the way it was written when it is not being played from a set.
  ///
  /// [keepingTheView] is for a newer upload of the score arriving while it is
  /// on the stand: the player goes on reading it the way they were.
  void _show(String musicXml, {bool keepingTheView = false}) {
    final parts = readParts(parseMusicXml(musicXml)).toList();
    var view = ScoreView.forParts([for (final part in parts) part.id]);
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
          .withTransposition(entry.readAt)
          .withHiddenParts(entry.view.hiddenParts);
      _space = _spaceFor(entry.view.zoom);
    }

    final piece = _collection?.entry;
    if (piece != null) {
      // The same out of a book, where how big it is drawn comes too: that is
      // this player's alone and is not added to anything.
      view = view
          .withTransposition(piece.readAt)
          .withHiddenParts(piece.view.hiddenParts);
      _space = _spaceFor(piece.view.zoom);
    }

    // Played from its details, it goes on being read the way it was being read
    // there — which is the entry's reading too when there is an entry, give or
    // take what was changed there in the moment before the stand was opened.
    final handover = widget.handover;
    if (handover != null) {
      view = view.withTransposition(handover.view.transposition).withHiddenParts([
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

    final app = AppScope.read(context);
    var set = app.sets.getSet(setId);
    if (set == null) {
      // A link into a set can be followed on a device that has not synced since
      // it was shared.
      await app.updateSets();
      set = app.sets.getSet(setId);
    }
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

    final app = AppScope.read(context);
    var collection = app.collections.getCollection(collectionId);
    if (collection == null) {
      await app.updateCollections();
      collection = app.collections.getCollection(collectionId);
    }
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
  double get _zoom =>
      (_space * _pinched / _writtenSpace).clamp(minZoom, maxZoom);

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
      inTheBackground(_saveViewToSet());
    } else if (_collection != null) {
      inTheBackground(_saveViewToCollection());
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
              savedReadAt: entry.readAt,
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
      final saved = await _app.sets.saveEntryView(
        context.set.id,
        context.entry.id,
        transposition: _readingOffset(
          band: context.entry.transposition,
          saved: context.entry.view.transposition,
          savedReadAt: context.entry.readAt,
          onScreen: view.transposition,
        ),
        hiddenParts: [...view.hiddenPartIds],
        zoom: _zoom,
      );
      // Where the entry comes in the set is read again rather than kept: a sync
      // can have reordered the gig while this was being written, and taking the
      // place it used to be at would put somebody else's song on the screen.
      final moved =
          saved.entries.indexWhere((entry) => entry.id == context.entry.id);
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
              savedReadAt: entry.readAt,
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
      final saved = await _app.collections.saveEntryView(
        context.collection.id,
        entry.id,
        transposition: _readingOffset(
          band: entry.transposition,
          saved: entry.view.transposition,
          savedReadAt: entry.readAt,
          onScreen: view.transposition,
        ),
        hiddenParts: [...view.hiddenPartIds],
        zoom: _zoom,
      );
      if (!mounted) return;
      final piece =
          saved.entries.where((piece) => piece.id == entry.id).firstOrNull;
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
      _say('This score cannot be downloaded because it has not been saved yet.');
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
      _say('This score cannot be downloaded because it has not been saved yet.');
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
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['musicxml', 'xml'],
    );
    final file = picked?.files.firstOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return;

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
    final app = AppScope.read(context);
    final scoreId = _scoreId ?? _newScoreId;

    try {
      await app.scores.putMusicXml(scoreId, musicXml);
      if (!mounted) return;
      if (_isNew) {
        // Uploaded, it is a score like any other and is at its own address, so
        // that reloading it or keeping it opens this score rather than another
        // empty upload page. The file is on this device by now, so the page at
        // that address opens straight onto it.
        inTheBackground(app.updateScores());
        Navigator.of(context).pushReplacementNamed(
          AppRoute.score(scoreId),
          arguments: AppRoute.renamed,
        );
        return;
      }
      setState(() => _scoreId = scoreId);
      _show(musicXml);
      await app.updateScores();
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
    Navigator.of(context).pushNamed(
      AppRoute.perform(
        widget.scoreId,
        setId: _set?.set.id,
        collectionId: _set == null ? _collection?.collection.id : null,
        entryId: _set?.entry.id ?? _collection?.entryId,
      ),
      arguments: view == null
          ? null
          : ScoreReadingHandover(
              view: view,
              zoom: _zoom,
              onReturn: _takeBackFromTheStand,
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
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: briefly
            ? const Duration(milliseconds: 2500)
            : const Duration(seconds: 4),
      ));
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
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final look = settings.pageLook(Theme.of(context).brightness);
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
    final app = AppScope.of(context);
    final mayView = app.user?.isScoreViewer == true;
    final score = _scoreId == null ? null : app.scores.getScore(_scoreId!);
    final paperName =
        (_set?.entry.description ?? _collection?.entry?.description ?? '')
            .trim();
    final title = _isPaper
        ? (paperName.isEmpty ? 'Played from paper' : paperName)
        : score?.title ?? (_isNew ? 'New score' : 'Score');

    if (!mayView) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Scores are for score viewers.')),
      );
    }
    return widget.performing
        ? _stand(app, title)
        : _details(app, title, score);
  }

  /// The way through the set or the collection this is played from, if it is.
  ///
  /// The collection is read as it is now rather than as it was when the page
  /// opened: the titles the way through it is sorted by arrive with the
  /// scores, after the page has opened, and a sync can bring in pieces
  /// somebody else put into the book. Which is why whatever draws this
  /// listens to both.
  _WayThrough? _wayThrough(App app) {
    final set = _set;
    if (set != null) {
      return _WayThrough.ofSet(set, performing: widget.performing);
    }
    final collection = _collection;
    // A collection is a book and not a running order, so its details have
    // no way through it: the piece is looked up, not played after the last.
    // On the stand the pieces either side are still a tap away.
    if (collection != null && widget.performing) {
      return _WayThrough.ofCollection(
        collection.refreshedFrom(
          app.collections.getCollection(collection.collection.id),
        ),
        titleOf: (scoreId) => app.scores.getScore(scoreId)?.title,
        performing: widget.performing,
      );
    }
    return null;
  }

  /// Opens the one before or after this one, in place of this one.
  void _go(String route) {
    _keepWhatIsWaiting();
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// What a bar of the way through is drawn from changing.
  Listenable _wayChanges(App app) =>
      Listenable.merge([app.collections, app.scores]);

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
  Widget _stand(App app, String title) {
    return ListenableBuilder(
      listenable: _wayChanges(app),
      builder: (context, _) => _standFor(_wayThrough(app), title),
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
                      onTap: () => Navigator.of(context).pushNamed(way.route),
                      child: Tooltip(
                        message:
                            way.isSet ? 'Open the set' : 'Open the collection',
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
  Widget _details(App app, String title, Score? score) {
    final mayEdit = app.user?.isScoreEditor == true;
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
          onDownloadAsOnScreen:
              _view == null || _view!.isPristine ? null : _downloadAsOnScreen,
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
        Text('How you read it',
            style: Theme.of(context).textTheme.titleMedium),
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
            listenable: _wayChanges(app),
            builder: (context, _) => switch (_wayThrough(app)) {
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
                  final panel =
                      (constraints.maxWidth * 0.38).clamp(280.0, 440.0);
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
class _SetContext {
  const _SetContext({
    required this.set,
    required this.index,
  });
  final int index;

  final ScoreSet set;

  SetEntry get entry => set.entries[index];
}

/// The way through the set or the collection a score is played from: where
/// this one comes in it, and what comes either side.
class _WayThrough {
  const _WayThrough({
    required this.isSet,
    required this.title,
    required this.route,
    required this.position,
    required this.count,
    required this.previous,
    required this.next,
    required this.note,
  });

  /// The way through a set, in its running order.
  ///
  /// The next song either way, one played from paper included. That is not
  /// stepped over: it is what the band is playing, and a player looking at the
  /// song after it is lost when the band starts that one.
  factory _WayThrough.ofSet(_SetContext context, {required bool performing}) {
    final set = context.set;
    String? nearest(int step) {
      final index = context.index + step;
      if (index < 0 || index >= set.entries.length) return null;
      final entry = set.entries[index];
      final scoreId = entry.scoreId;
      return scoreId == null
          ? AppRoute.paper(setId: set.id, entryId: entry.id)
          : (performing ? AppRoute.perform : AppRoute.score)(
              scoreId,
              setId: set.id,
              entryId: entry.id,
            );
    }

    return _WayThrough(
      isSet: true,
      title: set.displayTitle,
      route: AppRoute.set(set.id),
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
    final entries = entriesByTitle(collection.entries, titleOf);
    final index = entries.indexWhere((entry) => entry.id == context.entryId);
    if (index < 0) return null;

    String? nearest(int step) {
      final at = index + step;
      if (at < 0 || at >= entries.length) return null;
      final candidate = entries[at];
      final scoreId = candidate.scoreId;
      return scoreId == null
          ? AppRoute.paper(collectionId: collection.id, entryId: candidate.id)
          : (performing ? AppRoute.perform : AppRoute.score)(
              scoreId,
              collectionId: collection.id,
              entryId: candidate.id,
            );
    }

    return _WayThrough(
      isSet: false,
      title: collection.displayTitle,
      route: AppRoute.collection(collection.id),
      position: index + 1,
      count: entries.length,
      previous: nearest(-1),
      next: nearest(1),
      note: entries[index].description.trim(),
    );
  }

  final bool isSet;

  /// What the set or the collection is called, and where it is.
  final String title;
  final String route;

  /// Where this one comes in it, counted from one, and how many there are.
  final int position;
  final int count;

  /// Where the ones either side are, or null at either end.
  final String? previous;
  final String? next;

  /// What the set or the collection says next to this one.
  final String note;
}

/// The way through the set or the collection, as a bar of its own under the
/// details of a score.
class _WayBar extends StatelessWidget {
  const _WayBar({
    required this.way,
    required this.go,
  });

  final _WayThrough way;

  /// Opens the page at a route in place of this one.
  final void Function(String route) go;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = way.previous;
    final next = way.next;
    void open() => Navigator.of(context).pushNamed(way.route);

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
class _CollectionContext {
  const _CollectionContext({
    required this.collection,
    required this.entryId,
  });

  final Collection collection;
  final String entryId;

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
class _ScoreFacts extends StatelessWidget {
  const _ScoreFacts({
    required this.score,
  });

  final Score score;

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
      if (score.languages.isNotEmpty)
        ('Sung in', score.languages.join(', ')),
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
                  child: Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
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
class _ViewSettings extends StatelessWidget {
  const _ViewSettings({
    required this.view,
    required this.parts,
    required this.onChange,
    required this.keptAsYourReading,
  });

  final ScoreView view;
  final List<ScorePartRef> parts;
  final void Function(ScoreView Function(ScoreView)) onChange;

  /// Whether what is changed here is kept as this player's reading of the
  /// song, which it is when it is played from a set or a collection.
  final bool keptAsYourReading;

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
              onPressed: semitones > minTransposition
                  ? () =>
                      onChange((view) => view.withTransposition(semitones - 1))
                  : null,
            ),
            SizedBox(
              width: 36,
              child: Text('${semitones > 0 ? '+' : ''}$semitones',
                  textAlign: TextAlign.center),
            ),
            TransposeUpButton(
              onPressed: semitones < maxTransposition
                  ? () =>
                      onChange((view) => view.withTransposition(semitones + 1))
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
                      (view) => view.withPartVisible(part.id, visible)),
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
              onPressed:
                  view.isPristine ? null : () => onChange((view) => view.reset()),
            ),
            if (keptAsYourReading)
              Tooltip(
                message: "Only you see this. What the band plays is the"
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
class _Reading {
  _Reading.ofSong(SetEntry entry)
      : this._(entry.transposition, entry.view, entry.readAt);

  _Reading.ofPiece(CollectionEntry entry)
      : this._(entry.transposition, entry.view, entry.readAt);

  _Reading._(this.band, EntryView view, this.readAt)
      : saved = view.transposition,
        hiddenParts = view.hiddenParts,
        zoom = view.zoom;

  final int band;
  final int saved;
  final int readAt;
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
  int get hashCode => Object.hash(band, saved, readAt, zoom,
      Object.hashAllUnordered(hiddenParts));
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
  return (onScreen - band).clamp(minTransposition, maxTransposition);
}

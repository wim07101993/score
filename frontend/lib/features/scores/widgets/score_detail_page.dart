import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:score/app.dart';
import 'package:score/features/collections/models.dart'
    show Collection, CollectionEntry, entriesByTitle, maxZoom, minZoom;
import 'package:score/features/files/file_saver.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/musicxml_view.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/widgets/download_score_button.dart';
import 'package:score/features/scores/widgets/next_score_button.dart';
import 'package:score/features/scores/widgets/open_collection_button.dart';
import 'package:score/features/scores/widgets/open_set_button.dart';
import 'package:score/features/scores/widgets/part_visibility_chip.dart';
import 'package:score/features/scores/widgets/previous_score_button.dart';
import 'package:score/features/scores/widgets/save_my_view_button.dart';
import 'package:score/features/scores/widgets/show_as_written_button.dart';
import 'package:score/features/scores/widgets/transpose_down_button.dart';
import 'package:score/features/scores/widgets/transpose_up_button.dart';
import 'package:score/features/scores/widgets/upload_score_button.dart';
import 'package:score/features/scores/widgets/zoom_in_button.dart';
import 'package:score/features/scores/widgets/zoom_out_button.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/routes.dart';
import 'package:uuid/uuid.dart';

/// One score, drawn and played from.
///
/// How it is being looked at — the key it is read in, which parts are on screen
/// — is never stored and never travels back to the API. The document is what
/// the editor uploaded and stays that way; the view is something that happens
/// on the way to the screen.
class ScoreDetailPage extends StatefulWidget {
  const ScoreDetailPage({
    super.key,
    required this.scoreId,
    this.setId,
    this.collectionId,
    this.entryId,
  });

  /// `new` for a score that is about to be uploaded.
  final String scoreId;

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

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  static const _uuid = Uuid();
  List<ScorePartRef> _parts = const [];

  /// The score as it was uploaded. Transposing and hiding parts never touch it,
  /// so this stays what is downloaded and re-uploaded.
  String? _musicXml;

  String? _scoreId;
  ScoreView? _view;

  bool _loading = true;
  Object? _failure;

  /// What one staff space is worth on screen when the score is drawn the size
  /// it is written at — which is what a zoom of 1 means in a view.
  static const _writtenSpace = 7.5;

  /// As far as the zoom buttons go either way.
  static const _minSpace = 4.0;
  static const _maxSpace = 20.0;

  /// What one staff space is worth on screen — the zoom.
  double _space = _writtenSpace;

  /// The set this score is being played from, when it is being played from one.
  _SetContext? _set;

  /// The collection this score is being played from, when it is being played
  /// from one.
  _CollectionContext? _collection;

  bool get _isNew => widget.scoreId == 'new';

  @override
  void initState() {
    super.initState();
    _scoreId = _isNew ? null : widget.scoreId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = AppScope.read(context);

    if (app.user?.isScoreViewer != true) {
      setState(() => _loading = false);
      return;
    }
    if (_isNew) {
      setState(() => _loading = false);
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

      _show(musicXml);
      await app.scores.markViewed(widget.scoreId);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failure = error;
        });
      }
    }

    unawaited(app.updateScores());
  }

  /// Reads a score and starts it off being looked at the way the set says it is
  /// played, or the way it was written when it is not being played from a set.
  void _show(String musicXml) {
    final parts = readParts(parseMusicXml(musicXml)).toList();
    var view = ScoreView.forParts([for (final part in parts) part.id]);

    final entry = _set?.entry;
    if (entry != null) {
      // The score opens the way the band plays it and the way this player reads
      // it: the entry says the band is a tone down, the view says this player
      // reads that a fifth up, and what goes on screen is the two together.
      view = view
          .withTransposition(entry.readAt)
          .withHiddenParts(entry.view.hiddenParts);
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

    setState(() {
      _musicXml = musicXml;
      _parts = parts;
      _view = view;
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
    if (set.entries[index].scoreId != widget.scoreId) return;

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
    if (entry == null || entry.scoreId != widget.scoreId) return;

    _collection = _CollectionContext(collection: collection, entryId: entryId);
  }

  /// What one staff space is worth for a view drawn at [zoom], held to what
  /// the zoom buttons go to.
  double _spaceFor(double zoom) =>
      (_writtenSpace * zoom).clamp(_minSpace, _maxSpace);

  /// How big the score is drawn now, as a view says it: where 1 is the size it
  /// is written at.
  double get _zoom => (_space / _writtenSpace).clamp(minZoom, maxZoom);

  void _changeView(ScoreView Function(ScoreView) change) {
    final view = _view;
    if (view == null) return;
    setState(() => _view = change(view));
  }

  // -------------------------------------------------------------------------
  // PLAYING FROM A SET
  // -------------------------------------------------------------------------

  /// Whether the way the score is on screen is the way the set says it is
  /// played. While it is, there is nothing to save.
  bool get _viewMatchesEntry {
    final entry = _set?.entry;
    final view = _view;
    if (entry == null || view == null) return true;

    final hidden = entry.view.hiddenParts;
    return entry.readAt == view.transposition &&
        hidden.length == view.hiddenPartIds.length &&
        hidden.every(view.isHidden);
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

    final app = AppScope.read(this.context);
    try {
      final saved = await app.sets.saveEntryView(
        context.set.id,
        context.entry.id,
        transposition: view.transposition - context.entry.transposition,
        hiddenParts: [...view.hiddenPartIds],
      );
      // Where the entry comes in the set is read again rather than kept: a sync
      // can have reordered the gig while this was being written, and taking the
      // place it used to be at would put somebody else's song on the screen.
      final moved =
          saved.entries.indexWhere((entry) => entry.id == context.entry.id);
      if (!mounted) return;
      setState(() {
        _set = moved < 0 ? null : _SetContext(set: saved, index: moved);
      });
    } catch (error) {
      if (!mounted) return;
      _say('This view could not be saved: $error');
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
    return entry.readAt == view.transposition &&
        hidden.length == view.hiddenPartIds.length &&
        hidden.every(view.isHidden) &&
        (_spaceFor(entry.view.zoom) - _space).abs() < 0.01;
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

    final app = AppScope.read(this.context);
    try {
      final saved = await app.collections.saveEntryView(
        context.collection.id,
        entry.id,
        transposition: view.transposition - entry.transposition,
        hiddenParts: [...view.hiddenPartIds],
        zoom: _zoom,
      );
      if (!mounted) return;
      setState(() {
        _collection = saved.entries.any((piece) => piece.id == entry.id)
            ? _CollectionContext(collection: saved, entryId: entry.id)
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      _say('This view could not be saved: $error');
    }
  }

  // -------------------------------------------------------------------------
  // TAKING A SCORE AWAY, AND PUTTING ONE THERE
  // -------------------------------------------------------------------------

  /// The score as it is being looked at: the parts that are off screen are not
  /// in it, and it is in the key it is being read in. A score nobody has
  /// touched comes out as the file the editor uploaded, byte for byte.
  Future<void> _download() async {
    final musicXml = _musicXml;
    final scoreId = _scoreId;
    if (musicXml == null || scoreId == null) {
      _say('This score cannot be downloaded because it has not been saved yet.');
      return;
    }

    try {
      final written = musicXmlForView(musicXml, _view);
      await saveFile(
        filename: '$scoreId.musicxml',
        bytes: utf8.encode(written),
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
    final scoreId = _scoreId ?? _uuid.v4();

    try {
      await app.scores.putMusicXml(scoreId, musicXml);
      if (!mounted) return;
      if (_isNew) {
        // Uploaded, it is a score like any other and is at its own address, so
        // that reloading it or keeping it opens this score rather than another
        // empty upload page. The file is on this device by now, so the page at
        // that address opens straight onto it.
        unawaited(app.updateScores());
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

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final mayEdit = app.user?.isScoreEditor == true;
    final score = _scoreId == null ? null : app.scores.getScore(_scoreId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(score?.title ?? (_isNew ? 'New score' : 'Score')),
        actions: [
          if (_musicXml != null) ...[
            ZoomOutButton(
              onPressed: () =>
                  setState(() => _space = (_space - 0.8).clamp(_minSpace, _maxSpace)),
            ),
            ZoomInButton(
              onPressed: () =>
                  setState(() => _space = (_space + 0.8).clamp(_minSpace, _maxSpace)),
            ),
            DownloadScoreButton(onPressed: _download),
          ],
          if (mayEdit)
            UploadScoreButton(
              replacing: _scoreId != null,
              onPressed: _pickAndUpload,
            ),
        ],
      ),
      body: !mayView
          ? const Center(child: Text('Scores are for score viewers.'))
          : Column(
              children: [
                if (_set != null) _SetBar(context: _set!),
                if (_collection != null)
                  // Drawn from the collection as it is now rather than as it
                  // was when the page opened: the titles the way through it is
                  // sorted by arrive with the scores, after the page has
                  // opened, and a sync can bring in pieces somebody else put
                  // into the book.
                  ListenableBuilder(
                    listenable:
                        Listenable.merge([app.collections, app.scores]),
                    builder: (context, _) => _CollectionBar(
                      context: _collection!.refreshedFrom(
                        app.collections.getCollection(
                            _collection!.collection.id),
                      ),
                      titleOf: (scoreId) => app.scores.getScore(scoreId)?.title,
                    ),
                  ),
                if (_view != null)
                  _ViewControls(
                    view: _view!,
                    parts: _parts,
                    onChange: _changeView,
                    canSaveToSet: _canSaveView,
                    onSaveToSet: _set != null
                        ? _saveViewToSet
                        : _collection != null
                            ? _saveViewToCollection
                            : null,
                  ),
                Expanded(child: _sheet()),
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

/// The way through the set: what came before this song and what comes after.
class _SetBar extends StatelessWidget {
  const _SetBar({
    required this.context,
  });

  final _SetContext context;

  @override
  Widget build(BuildContext buildContext) {
    final theme = Theme.of(buildContext);
    final set = context.set;
    final entry = context.entry;

    /// The nearest song that way that has a score to open. One that is played
    /// from paper has nothing to put on the stand, so it is stepped over.
    String? nearest(int step) {
      for (var index = context.index + step;
          index >= 0 && index < set.entries.length;
          index += step) {
        final entry = set.entries[index];
        final scoreId = entry.scoreId;
        if (scoreId == null) continue;
        return AppRoute.score(scoreId, setId: set.id, entryId: entry.id);
      }
      return null;
    }

    void go(String? route) {
      if (route == null) return;
      Navigator.of(buildContext).pushReplacementNamed(route);
    }

    final previous = nearest(-1);
    final next = nearest(1);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            PreviousScoreButton(
              onPressed: previous == null ? null : () => go(previous),
            ),
            OpenSetButton(
              title: set.displayTitle,
              onPressed: () => Navigator.of(buildContext)
                  .pushNamed(AppRoute.set(set.id)),
            ),
            Text(
              '${context.index + 1} of ${set.entries.length}',
              style: theme.textTheme.labelMedium,
            ),
            NextScoreButton(
              onPressed: next == null ? null : () => go(next),
            ),
            if (entry.description.trim().isNotEmpty)
              Expanded(
                child: Text(
                  entry.description,
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

/// The way through the collection: the pieces either side of this one, by
/// title.
class _CollectionBar extends StatelessWidget {
  const _CollectionBar({
    required this.context,
    required this.titleOf,
  });

  final _CollectionContext context;
  final String? Function(String scoreId) titleOf;

  @override
  Widget build(BuildContext buildContext) {
    final theme = Theme.of(buildContext);
    final collection = context.collection;
    final entries = entriesByTitle(collection.entries, titleOf);
    final index = entries.indexWhere((entry) => entry.id == context.entryId);
    if (index < 0) return const SizedBox.shrink();
    final entry = entries[index];

    /// The nearest piece that way that has a score to open. One that has yet
    /// to be scanned has nothing to put on the stand, so it is stepped over.
    String? nearest(int step) {
      for (var at = index + step; at >= 0 && at < entries.length; at += step) {
        final candidate = entries[at];
        final scoreId = candidate.scoreId;
        if (scoreId == null) continue;
        return AppRoute.score(
          scoreId,
          collectionId: collection.id,
          entryId: candidate.id,
        );
      }
      return null;
    }

    void go(String? route) {
      if (route == null) return;
      Navigator.of(buildContext).pushReplacementNamed(route);
    }

    final previous = nearest(-1);
    final next = nearest(1);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            PreviousScoreButton(
              onPressed: previous == null ? null : () => go(previous),
            ),
            OpenCollectionButton(
              title: collection.displayTitle,
              onPressed: () => Navigator.of(buildContext)
                  .pushNamed(AppRoute.collection(collection.id)),
            ),
            Text(
              '${index + 1} of ${entries.length}',
              style: theme.textTheme.labelMedium,
            ),
            NextScoreButton(
              onPressed: next == null ? null : () => go(next),
            ),
            if (entry.description.trim().isNotEmpty)
              Expanded(
                child: Text(
                  entry.description,
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

/// How the score is read: the key, and which parts are on screen.
class _ViewControls extends StatelessWidget {
  const _ViewControls({
    required this.view,
    required this.parts,
    required this.onChange,
    required this.canSaveToSet,
    this.onSaveToSet,
  });

  final ScoreView view;
  final List<ScorePartRef> parts;
  final void Function(ScoreView Function(ScoreView)) onChange;
  final bool canSaveToSet;
  final Future<void> Function()? onSaveToSet;

  @override
  Widget build(BuildContext context) {
    final semitones = view.transposition;

    return ExpansionTile(
      title: Row(
        children: [
          const Text('View'),
          const SizedBox(width: 12),
          if (semitones != 0)
            Chip(
              label: Text(
                  '${semitones > 0 ? '+' : ''}$semitones semitones'),
              visualDensity: VisualDensity.compact,
            ),
          if (view.hiddenPartIds.isNotEmpty) ...[
            const SizedBox(width: 6),
            Chip(
              label: Text('${view.hiddenPartIds.length} part'
                  '${view.hiddenPartIds.length == 1 ? '' : 's'} hidden'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Transpose'),
              const Spacer(),
              TransposeDownButton(
                onPressed: semitones > minTransposition
                    ? () => onChange(
                        (view) => view.withTransposition(semitones - 1))
                    : null,
              ),
              SizedBox(
                width: 36,
                child: Text('${semitones > 0 ? '+' : ''}$semitones',
                    textAlign: TextAlign.center),
              ),
              TransposeUpButton(
                onPressed: semitones < maxTransposition
                    ? () => onChange(
                        (view) => view.withTransposition(semitones + 1))
                    : null,
              ),
            ],
          ),
        ),
        if (parts.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
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
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            children: [
              ShowAsWrittenButton(
                onPressed: view.isPristine
                    ? null
                    : () => onChange((view) => view.reset()),
              ),
              if (onSaveToSet != null)
                SaveMyViewButton(
                  onPressed: canSaveToSet ? onSaveToSet : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

void unawaited(Future<void> future) {
  future.catchError((Object error) {
    debugPrint('a background task failed: $error');
  });
}

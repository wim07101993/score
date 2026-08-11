import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/file_saver.dart';
import '../domains/sets/models.dart';
import '../notation/musicxml/parser.dart';
import '../notation/parts.dart';
import '../notation/score_sheet.dart';
import '../notation/view/musicxml_view.dart';
import '../notation/view/score_view.dart';
import 'routes.dart';

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
    this.entryId,
  });

  /// `new` for a score that is about to be uploaded.
  final String scoreId;

  final String? setId;
  final String? entryId;

  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  static const _uuid = Uuid();

  /// The score as it was uploaded. Transposing and hiding parts never touch it,
  /// so this stays what is downloaded and re-uploaded.
  String? _musicXml;

  String? _scoreId;
  ScoreView? _view;
  List<ScorePartRef> _parts = const [];

  bool _loading = true;
  Object? _failure;

  /// What one staff space is worth on screen — the zoom.
  double _space = 7.5;

  /// The set this score is being played from, when it is being played from one.
  _SetContext? _set;

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

    final musicXml = utf8.decode(bytes, allowMalformed: true);

    // Read before it is sent: a file that cannot be read is a file the band
    // cannot play, and finding that out after it is on the server is finding it
    // out too late.
    try {
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
            IconButton(
              tooltip: 'Smaller',
              icon: const Icon(Icons.zoom_out),
              onPressed: () =>
                  setState(() => _space = (_space - 0.8).clamp(4.0, 20.0)),
            ),
            IconButton(
              tooltip: 'Bigger',
              icon: const Icon(Icons.zoom_in),
              onPressed: () =>
                  setState(() => _space = (_space + 0.8).clamp(4.0, 20.0)),
            ),
            IconButton(
              tooltip: 'Download the score file',
              icon: const Icon(Icons.download),
              onPressed: _download,
            ),
          ],
          if (mayEdit)
            IconButton(
              tooltip: _scoreId == null ? 'Upload' : 'Replace this score',
              icon: const Icon(Icons.upload_file),
              onPressed: _pickAndUpload,
            ),
        ],
      ),
      body: !mayView
          ? const Center(child: Text('Scores are for score viewers.'))
          : Column(
              children: [
                if (_set != null) _SetBar(context: _set!),
                if (_view != null)
                  _ViewControls(
                    view: _view!,
                    parts: _parts,
                    onChange: _changeView,
                    canSaveToSet: _set != null && !_viewMatchesEntry,
                    onSaveToSet: _set == null ? null : _saveViewToSet,
                  ),
                Expanded(child: _sheet()),
              ],
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
}

/// Which set this score is being played from, and where in it.
class _SetContext {
  const _SetContext({required this.set, required this.index});

  final ScoreSet set;
  final int index;

  SetEntry get entry => set.entries[index];
}

/// The way through the set: what came before this song and what comes after.
class _SetBar extends StatelessWidget {
  const _SetBar({required this.context});

  final _SetContext context;

  @override
  Widget build(BuildContext buildContext) {
    final theme = Theme.of(buildContext);
    final set = context.set;
    final entry = context.entry;

    String? at(int index) {
      if (index < 0 || index >= set.entries.length) return null;
      return AppRoute.score(
        set.entries[index].scoreId,
        setId: set.id,
        entryId: set.entries[index].id,
      );
    }

    void go(String? route) {
      if (route == null) return;
      Navigator.of(buildContext).pushReplacementNamed(route);
    }

    final previous = at(context.index - 1);
    final next = at(context.index + 1);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'The score before this one',
              icon: const Icon(Icons.chevron_left),
              onPressed: previous == null ? null : () => go(previous),
            ),
            TextButton(
              onPressed: () => Navigator.of(buildContext)
                  .pushNamed(AppRoute.set(set.id)),
              child: Text(set.displayTitle),
            ),
            Text(
              '${context.index + 1} of ${set.entries.length}',
              style: theme.textTheme.labelMedium,
            ),
            IconButton(
              tooltip: 'The score after this one',
              icon: const Icon(Icons.chevron_right),
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
              Expanded(
                child: Slider(
                  value: semitones.toDouble(),
                  min: minTransposition.toDouble(),
                  max: maxTransposition.toDouble(),
                  divisions: maxTransposition - minTransposition,
                  label: '${semitones > 0 ? '+' : ''}$semitones',
                  // Redrawing a score is expensive enough that doing it for
                  // every pixel of a drag is not worth it: dragging moves the
                  // number and letting go redraws.
                  onChanged: (value) {},
                  onChangeEnd: (value) =>
                      onChange((view) => view.withTransposition(value.round())),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('${semitones > 0 ? '+' : ''}$semitones',
                    textAlign: TextAlign.end),
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
                  FilterChip(
                    label: Text(part.name),
                    selected: !view.isHidden(part.id),
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
              TextButton(
                onPressed: view.isPristine
                    ? null
                    : () => onChange((view) => view.reset()),
                child: const Text('Show as written'),
              ),
              if (onSaveToSet != null)
                Tooltip(
                  message: 'Only you see this. What the band plays is the'
                      " owner's to say.",
                  child: FilledButton.tonal(
                    onPressed: canSaveToSet ? onSaveToSet : null,
                    child: const Text('Save as how I read it'),
                  ),
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

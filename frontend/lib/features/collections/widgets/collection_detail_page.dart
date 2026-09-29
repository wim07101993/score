import 'dart:async';

import 'package:flutter/material.dart';
import 'package:score/app.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/collections/widgets/add_paper_entry_button.dart';
import 'package:score/features/collections/widgets/add_score_to_collection_chip.dart';
import 'package:score/features/collections/widgets/collection_description_field.dart';
import 'package:score/features/collections/widgets/collection_entry_description_field.dart';
import 'package:score/features/collections/widgets/collection_shared_with_field.dart';
import 'package:score/features/collections/widgets/collection_title_field.dart';
import 'package:score/features/collections/widgets/confirm_delete_collection_button.dart';
import 'package:score/features/collections/widgets/delete_collection_button.dart';
import 'package:score/features/collections/widgets/keep_collection_button.dart';
import 'package:score/features/collections/widgets/open_collection_entry_button.dart';
import 'package:score/features/collections/widgets/paper_entry_field.dart';
import 'package:score/features/collections/widgets/remove_collection_entry_button.dart';
import 'package:score/features/collections/widgets/save_collection_button.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/widgets/score_search_field.dart';
import 'package:score/features/sets/widgets/semitone_down_button.dart';
import 'package:score/features/sets/widgets/semitone_up_button.dart';
import 'package:score/features/sets/widgets/show_all_parts_button.dart';
import 'package:score/routes.dart';
import 'package:uuid/uuid.dart';

/// One collection, written.
///
/// What the collection *is* — the group of pieces, and who may read it — waits
/// for the save button. What is *in* it does not: an entry is a resource of its
/// own, so adding a piece, taking one out, and changing its note or key each
/// land as they are made. There is nothing to save afterwards, and nothing to
/// lose by leaving the page.
///
/// The pieces are listed by title, and have no numbers: a collection has no
/// order, so what is here is by name, which is how somebody looking for a piece
/// reads a list.
class CollectionDetailPage extends StatefulWidget {
  const CollectionDetailPage({
    super.key,
    required this.collectionId,
  });

  /// `new` for a collection that has not been saved yet.
  final String collectionId;

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  static const _uuid = Uuid();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sharedWith = TextEditingController();
  final _filter = TextEditingController();
  final _paperEntry = TextEditingController();
  final _paperEntryFocus = FocusNode();

  /// Where each piece is drawn, so that one that is asked for again can be
  /// scrolled to.
  final Map<String, GlobalKey> _entryKeys = {};

  late String _collectionId;

  /// Whether what has been typed says something the stored collection does
  /// not.
  bool _dirty = false;
  bool _loading = true;

  /// The piece that was just asked for and is already here, lit for a moment.
  String? _pointedAt;
  Timer? _pointing;

  void Function(CollectionSyncProblem)? _problemListener;

  @override
  void initState() {
    super.initState();
    _collectionId =
        widget.collectionId == 'new' ? _uuid.v4() : widget.collectionId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    final listener = _problemListener;
    if (listener != null) {
      AppScope.read(context).collections.removeSyncProblemListener(listener);
    }
    _pointing?.cancel();
    _title.dispose();
    _description.dispose();
    _sharedWith.dispose();
    _filter.dispose();
    _paperEntry.dispose();
    _paperEntryFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);

    // A collection this device has is drawn from what it has, network or no
    // network. One it has never heard of is asked about first: a link into a
    // collection can be followed on a device that has not synced since it was
    // shared, and drawing an empty one to type over would be a lie about what
    // is stored under that id.
    if (widget.collectionId != 'new' &&
        app.collections.getCollection(_collectionId) == null) {
      await app.updateCollections();
    }

    if (!mounted) return;
    _readFromStored();
    setState(() => _loading = false);

    // Giving up on an edit is the one thing this app does behind the player's
    // back, so it says so when it happens.
    _problemListener = (problem) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '"${problem.title.isEmpty ? 'A collection' : problem.title}" could'
          ' not be saved on the server (${problem.action}), and the change has'
          ' been taken back: ${problem.error.detail}',
        ),
      ));
      if (problem.collectionId == _collectionId && !_dirty) {
        _readFromStored();
        setState(() {});
      }
    };
    app.collections.addSyncProblemListener(_problemListener!);

    // The scores are what the pieces are called by, and they may bring in ones
    // this collection names; and, when nothing is being typed, the sync may
    // bring in a newer version of the collection itself.
    await app.updateScores();
    if (widget.collectionId != 'new') {
      await app.updateCollections();
    }
    if (mounted && !_dirty) {
      _readFromStored();
      setState(() {});
    }
  }

  void _readFromStored() {
    final collection =
        AppScope.read(context).collections.getCollection(_collectionId);
    _title.text = collection?.title ?? '';
    _description.text = collection?.description ?? '';
    _sharedWith.text = (collection?.sharedWith ?? const []).join('\n');
    _dirty = false;
  }

  Collection? get _stored =>
      AppScope.read(context).collections.getCollection(_collectionId);

  /// Whose the collection is, is something a sync can change its mind about,
  /// so this is read from the collection every time rather than settled once
  /// when the page is opened.
  bool get _isOwner => _stored?.isOwner ?? true;

  /// Whether the collection is stored at all. One that is not is one there is
  /// nothing to put a piece into yet: what is in it hangs off a collection, and
  /// the collection has to exist first.
  bool get _isStored => _stored != null;

  Future<void> _save() async {
    final app = AppScope.read(context);
    try {
      await app.collections.saveCollection(
        id: _collectionId,
        title: _title.text,
        description: _description.text,
        sharedWith: _sharedWith.text
            .split(RegExp(r'[\n,;]'))
            .map((address) => address.trim())
            .where((address) => address.isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      setState(() => _dirty = false);
      if (widget.collectionId == 'new') {
        // Saved, it is a collection like any other and is at its own address,
        // so that reloading it or keeping it opens this collection rather than
        // a new empty one.
        Navigator.of(context).pushReplacementNamed(
          AppRoute.collection(_collectionId),
          arguments: AppRoute.renamed,
        );
      }
    } catch (error) {
      if (mounted) _say('The collection could not be saved: $error');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this collection?'),
        content: const Text('The scores in it stay where they are.'),
        actions: [
          KeepCollectionButton(
              onPressed: () => Navigator.of(context).pop(false)),
          ConfirmDeleteCollectionButton(
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AppScope.read(context).collections.deleteCollection(_collectionId);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _say('The collection could not be deleted: $error');
    }
  }

  /// Writes one piece of the collection. Everything about an entry is written
  /// as it is changed rather than waiting for a save button: an entry is a
  /// resource of its own, so there is nothing it has to be saved along with.
  ///
  /// A piece the collection already holds is not an error to show: it is what
  /// the player wanted, so the entry it is already in is what they are taken
  /// to.
  Future<void> _writeEntry({
    String? id,
    String? scoreId,
    bool onPaper = false,
    String? description,
    int? transposition,
  }) async {
    try {
      await AppScope.read(context).collections.saveEntry(
            _collectionId,
            id: id,
            scoreId: scoreId,
            onPaper: onPaper,
            description: description,
            transposition: transposition,
          );
    } on ScoreAlreadyInCollectionException catch (already) {
      _pointAt(already.entryId);
    } catch (error) {
      if (mounted) {
        _say('That piece could not be put into the collection: $error');
      }
    }
  }

  /// Shows the player the piece they just asked for, which is already here.
  ///
  /// A collection holds a piece once, so adding one that is in it is not a
  /// refusal — it is being told where it is. Scrolling to it and lighting it
  /// for a moment says that without a dialog to dismiss.
  void _pointAt(String entryId) {
    if (!mounted) return;
    final target = _entryKeys[entryId]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
      );
    }
    _pointing?.cancel();
    setState(() => _pointedAt = entryId);
    _pointing = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _pointedAt = null);
    });
  }

  /// Puts a piece into the collection that this app has no score of.
  ///
  /// The cursor stays in the box afterwards, since filling a book in is typing
  /// one line after another.
  Future<void> _addPaperEntry() async {
    final description = _paperEntry.text.trim();
    if (description.isEmpty) {
      _paperEntryFocus.requestFocus();
      return;
    }

    _paperEntry.clear();
    setState(() {});
    await _writeEntry(onPaper: true, description: description);
    if (mounted) _paperEntryFocus.requestFocus();
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _stateOf(Collection? collection) {
    if (!_isOwner) {
      // Not read-only: what is in it is theirs, but how you read it is yours.
      return collection?.owesAnything == true
          ? 'shared with you — your reading is not sent yet'
          : 'shared with you';
    }
    if (_dirty) return 'not saved';
    if (collection == null) return 'new collection';
    if (collection.owesAnything) return 'saved here, not sent yet';
    return 'saved';
  }

  Widget _about(bool owner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollectionTitleField(
          controller: _title,
          enabled: owner,
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        CollectionDescriptionField(
          controller: _description,
          enabled: owner,
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }

  Widget _entries(App app, Collection? collection, bool owner) {
    final entries = entriesByTitle(
      collection?.entries ?? const <CollectionEntry>[],
      (scoreId) => app.scores.getScore(scoreId)?.title,
    );
    _entryKeys.removeWhere(
        (id, _) => !entries.any((entry) => entry.id == id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('In this collection',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (!_isStored)
          const Text(
            'Save the collection first. What is in it is stored piece by'
            ' piece, so there has to be a collection to put them in.',
          )
        else if (entries.isEmpty)
          const Text('Nothing in this collection yet. Add the pieces that'
              ' belong in it below.')
        else
          for (final entry in entries)
            _EntryCard(
              key: _entryKeys.putIfAbsent(entry.id, GlobalKey.new),
              entry: entry,
              collectionId: _collectionId,
              owner: owner,
              pointedAt: _pointedAt == entry.id,
              score: switch (entry.scoreId) {
                final scoreId? => app.scores.getScore(scoreId),
                null => null,
              },
              onDescription: (text) =>
                  _writeEntry(id: entry.id, description: text),
              onGroupTransposition: (semitones) =>
                  _writeEntry(id: entry.id, transposition: semitones),
              onRemove: () async {
                try {
                  await app.collections.deleteEntry(_collectionId, entry.id);
                } catch (error) {
                  if (mounted) {
                    _say('That piece could not be taken out of the'
                        ' collection: $error');
                  }
                }
              },
            ),
      ],
    );
  }

  Widget _picker(App app, Collection? collection) {
    final needle = _filter.text.trim();
    final scores = app.scores.scores
        .where((score) => score.matches(needle))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a piece', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ScoreSearchField(
          controller: _filter,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (app.scores.scores.isEmpty)
          const Text('No scores on this device to add. They arrive with the'
              ' next sync.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final score in scores)
                switch (collection?.entries
                    .where((entry) => entry.scoreId == score.id)
                    .firstOrNull) {
                  final alreadyIn? => AddScoreToCollectionChip(
                      title: score.title,
                      alreadyIn: true,
                      onPressed: () => _pointAt(alreadyIn.id),
                    ),
                  null => AddScoreToCollectionChip(
                      title: score.title,
                      alreadyIn: false,
                      onPressed: () => _writeEntry(scoreId: score.id),
                    ),
                },
            ],
          ),
        const SizedBox(height: 16),
        // Half of what is in a book is on paper until somebody gets round to
        // scanning it, and a collection that could only name what has been
        // uploaded is not the collection.
        const Text(
          'Or a piece that is not in here — one that has yet to be scanned.'
          ' What you write is what it is called, and it is the only name it'
          ' has until somebody scans it.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PaperEntryField(
                controller: _paperEntry,
                focusNode: _paperEntryFocus,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _addPaperEntry(),
              ),
            ),
            const SizedBox(width: 8),
            AddPaperEntryButton(
              onPressed:
                  _paperEntry.text.trim().isEmpty ? null : _addPaperEntry,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sharing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shared with', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'One address per line. Everyone here can read the collection and'
          ' play from it; changing it stays yours.',
        ),
        const SizedBox(height: 8),
        CollectionSharedWithField(
          controller: _sharedWith,
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.user?.isScoreViewer != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection')),
        body: const Center(
          child: Text(
              'Collections are for score viewers, and this account is not one.'),
        ),
      );
    }

    // The titles the pieces are listed by are in the scores, so a list of
    // them is drawn again when the scores change as well as when the
    // collection does.
    return ListenableBuilder(
      listenable: Listenable.merge([app.collections, app.scores]),
      builder: (context, _) {
        final collection = _stored;
        final owner = _isOwner;

        return Scaffold(
          appBar: AppBar(
            title: Text(collection?.displayTitle ?? 'New collection'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text(_stateOf(collection))),
              ),
              if (owner)
                SaveCollectionButton(onPressed: _dirty ? _save : null),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _about(owner),
                    const SizedBox(height: 24),
                    _entries(app, collection, owner),
                    const SizedBox(height: 24),
                    if (owner && _isStored) _picker(app, collection),
                    if (owner) ...[
                      const SizedBox(height: 24),
                      _sharing(),
                      const SizedBox(height: 32),
                      if (_isStored)
                        DeleteCollectionButton(onPressed: _delete),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// One piece of the collection: what it is, how the group plays it, and how
/// this player reads it.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.collectionId,
    required this.owner,
    required this.pointedAt,
    required this.score,
    required this.onDescription,
    required this.onGroupTransposition,
    required this.onRemove,
  });

  final CollectionEntry entry;
  final String collectionId;
  final bool owner;

  /// Whether this is the piece that was just asked for again, and is lit.
  final bool pointedAt;

  final Score? score;
  final void Function(String description) onDescription;
  final void Function(int semitones) onGroupTransposition;
  final Future<void> Function() onRemove;

  /// Stores how this player reads the piece. What is not said is kept as it
  /// is: the repository writes a view whole, filling in what was left out.
  Future<void> _saveMyView(
    BuildContext context, {
    int? transposition,
    List<String>? hiddenParts,
  }) async {
    try {
      await AppScope.read(context).collections.saveEntryView(
            collectionId,
            entry.id,
            transposition: transposition,
            hiddenParts: hiddenParts,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('How you read this one could not be saved:'
                  ' $error')),
        );
      }
    }
  }

  Widget _name(ThemeData theme) {
    final muted = TextStyle(
      color: theme.colorScheme.outline,
      fontStyle: FontStyle.italic,
    );
    return switch ((entry.scoreId, score)) {
      (_, final score?) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(score.title, style: theme.textTheme.titleSmall),
            // A book is looked through by who wrote what is in it as much as
            // by what it is called.
            if (score.creatorNames.isNotEmpty)
              Text(score.creatorNames.join(', '),
                  style: theme.textTheme.bodySmall),
          ],
        ),
      // A piece that has yet to be scanned. It has no score to take a title
      // from, so it is called by what is written next to it.
      (null, _) => Tooltip(
          message: 'Not scanned yet; there is no score here to open.',
          child: Text(
            entry.nameWith((_) => null),
            style: theme.textTheme.titleSmall?.merge(muted),
          ),
        ),
      (final scoreId?, _) => Tooltip(
          message: scoreId,
          child: Text('Not on this device yet', style: muted),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final read = entry.readAt;
    final sum = entry.transposition + entry.view.transposition;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: pointedAt ? theme.colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _name(theme)),
                OpenCollectionEntryButton(
                  onPressed: switch (entry.scoreId) {
                    // Straight to the music. Opening a piece of a collection
                    // is opening it to play it, not to read who wrote it.
                    final scoreId? => () => Navigator.of(context).pushNamed(
                          AppRoute.score(scoreId,
                              collectionId: collectionId, entryId: entry.id),
                        ),
                    // There is nothing to open for a piece with no score.
                    null => null,
                  },
                ),
                if (owner) RemoveCollectionEntryButton(onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            CollectionEntryDescriptionField(
              initialValue: entry.description,
              isTheOnlyName: entry.isOnPaper,
              enabled: owner,
              onSubmitted: onDescription,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Semitones(
                  label: 'all',
                  tooltip: 'The key this one is played in, counted in'
                      ' semitones from where it is written. Everyone sees'
                      ' this.',
                  value: entry.transposition,
                  enabled: owner,
                  onChanged: onGroupTransposition,
                ),
                const Text('+'),
                _Semitones(
                  label: 'me',
                  tooltip: 'How far you read it on top of that, again in'
                      ' semitones. Only you see this.',
                  value: entry.view.transposition,
                  enabled: true,
                  onChanged: (semitones) =>
                      _saveMyView(context, transposition: semitones),
                ),
                Tooltip(
                  message: 'What the two of them come to: the key this one'
                      ' opens at for you.',
                  child: Text(
                    read == 0
                        ? '= as written'
                        : '= ${read > 0 ? '+' : ''}$read semitones'
                            '${read != sum ? ' (as far as it goes)' : ''}',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Which parts are off screen is not something to pick from a list
            // here: the parts a score has are in its document, and the
            // document is not read until the score is drawn. So it is set
            // while playing — on the score itself — and all this says is how
            // it stands and how to undo it.
            Row(
              children: [
                Text(
                  entry.view.hiddenParts.isEmpty
                      ? 'every part on your screen'
                      : '${entry.view.hiddenParts.length} part'
                          '${entry.view.hiddenParts.length == 1 ? '' : 's'}'
                          ' off your screen',
                  style: theme.textTheme.bodySmall,
                ),
                if (entry.view.hiddenParts.isNotEmpty)
                  ShowAllPartsButton(
                    onPressed: () =>
                        _saveMyView(context, hiddenParts: const []),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Semitones extends StatelessWidget {
  const _Semitones({
    required this.label,
    required this.tooltip,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String tooltip;
  final int value;
  final bool enabled;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          SemitoneDownButton(
            onPressed: enabled && value > minTransposition
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text('${value > 0 ? '+' : ''}$value',
                textAlign: TextAlign.center),
          ),
          SemitoneUpButton(
            onPressed: enabled && value < maxTransposition
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

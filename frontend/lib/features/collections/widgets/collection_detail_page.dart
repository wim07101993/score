import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/behaviours/delete_collection.dart';
import 'package:score/features/collections/behaviours/delete_collection_entry.dart';
import 'package:score/features/collections/behaviours/save_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/widgets/add_score_to_collection_chip.dart';
import 'package:score/features/collections/widgets/collection_description_field.dart';
import 'package:score/features/collections/widgets/collection_entry_description_field.dart';
import 'package:score/features/collections/widgets/collection_title_field.dart';
import 'package:score/features/collections/widgets/delete_collection_button.dart';
import 'package:score/features/collections/widgets/open_collection_entry_button.dart';
import 'package:score/features/collections/widgets/remove_collection_entry_button.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_list/filter/score_search_field.dart';
import 'package:score/features/scores/widgets/score_list/score_library.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/router.dart';
import 'package:score/widgets/confirm_delete_button.dart';
import 'package:score/widgets/error_snack_bar.dart';
import 'package:score/widgets/keep_button.dart';
import 'package:score/widgets/save_button.dart';
import 'package:score/widgets/semitones.dart';
import 'package:score/widgets/shared_with_field.dart';
import 'package:score/widgets/show_all_parts_button.dart';
import 'package:score/widgets/unsaved_changes_guard.dart';
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
@RoutePage()
class const CollectionDetailPage({
  super.key,

  /// `new` for a collection that has not been saved yet.
  @PathParam('collectionId') required final String collectionId,
}) extends StatefulWidget {
  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final _auth = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();
  final _collections = GetIt.I<CollectionsNotifier>();

  static const _uuid = Uuid();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sharedWith = TextEditingController();
  final _filter = TextEditingController();

  /// Where each piece is drawn, so that one that is asked for again can be
  /// scrolled to.
  final Map<String, GlobalKey> _entryKeys = {};

  late String _collectionId;

  /// Whether what has been typed says something the stored collection does
  /// not.
  bool _dirty = false;
  bool _loading = true;

  /// Whether the collection is open to be changed, rather than to be read and
  /// played from. Only ever for its owner.
  ///
  /// Read is what a collection is opened as, the way a set is: it is a book to
  /// find a piece in and play it, and a page of fields and buttons to take a
  /// piece out with is not that. A new one and an empty one open to be changed
  /// instead — there is nothing to read in either.
  bool _editing = false;

  /// The piece that was just asked for and is already here, lit for a moment.
  String? _pointedAt;
  Timer? _pointing;

  @override
  void initState() {
    super.initState();
    _filter.addListener(_onFilterChanged);
    _collectionId = widget.collectionId == 'new'
        ? _uuid.v4()
        : widget.collectionId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onFilterChanged() => setState(() {});

  @override
  void dispose() {
    _collections.removeListener(_takeStoredChanges);
    _pointing?.cancel();
    _title.dispose();
    _description.dispose();
    _sharedWith.dispose();
    _filter
      ..removeListener(_onFilterChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // A collection this device has is drawn from what it has, network or no
    // network. One it has never heard of is asked about first: a link into a
    // collection can be followed on a device that has not synced since it was
    // shared, and drawing an empty one to type over would be a lie about what
    // is stored under that id.
    if (widget.collectionId != 'new' &&
        _collections.getCollection(_collectionId) == null) {
      await GetIt.I<SyncCollections>()();
    }

    if (!mounted) return;
    _readFromStored();
    final stored = _collections.getCollection(_collectionId);
    setState(() {
      _loading = false;
      _editing =
          widget.collectionId == 'new' ||
          (stored != null && stored.isOwner && stored.entries.isEmpty);
    });

    _collections.addListener(_takeStoredChanges);

    // The scores are what the pieces are called by, and they may bring in ones
    // this collection names; and, when nothing is being typed, the sync may
    // bring in a newer version of the collection itself.
    await GetIt.I<SyncScores>()();
    if (widget.collectionId != 'new') {
      await GetIt.I<SyncCollections>()();
    }
    if (mounted && !_dirty) {
      _readFromStored();
      setState(() {});
    }
  }

  /// Asks the server for the collection again, for a page that found it was
  /// not here.
  Future<void> _retry() async {
    setState(() => _loading = true);
    await GetIt.I<SyncCollections>()();
    if (!mounted) return;
    setState(() {
      _readFromStored();
      _loading = false;
    });
  }

  /// What a sync or another page stored for this collection is what the
  /// fields show, for as long as nothing is being typed into them: fields that
  /// went on showing what the collection was would be sent back by the next
  /// save, over it.
  void _takeStoredChanges() {
    if (!mounted || _dirty) return;
    setState(_readFromStored);
  }

  void _readFromStored() {
    final collection = _collections.getCollection(_collectionId);
    // Only what differs is written: writing a field puts its cursor at the end.
    void show(TextEditingController field, String text) {
      if (field.text != text) field.text = text;
    }

    show(_title, collection?.title ?? '');
    show(_description, collection?.description ?? '');
    show(_sharedWith, (collection?.sharedWith ?? const []).join('\n'));
    _dirty = false;
  }

  Collection? get _stored => _collections.getCollection(_collectionId);

  /// Whose the collection is, is something a sync can change its mind about,
  /// so this is read from the collection every time rather than settled once
  /// when the page is opened.
  bool get _isOwner => _stored?.isOwner ?? true;

  /// Whether the collection is stored at all. One that is not is one there is
  /// nothing to put a piece into yet: what is in it hangs off a collection, and
  /// the collection has to exist first.
  bool get _isStored => _stored != null;

  Future<void> _save() async {
    final title = _title.text;
    final description = _description.text;
    final sharedWith = _sharedWith.text;
    try {
      (await GetIt.I<SaveCollection>()(
        SaveCollectionParams(
          id: _collectionId,
          title: title,
          description: description,
          sharedWith: addressesIn(sharedWith),
        ),
      )).orThrow();
      if (!mounted) return;
      // Only what was sent is saved. Whatever was typed while the write was
      // out is still to be saved; and when nothing was, the fields show what
      // is stored now, which after a refused write is what the server has.
      if (_title.text == title &&
          _description.text == description &&
          _sharedWith.text == sharedWith) {
        setState(_readFromStored);
      }
      // Only once nothing typed is left unsaved: the page at the new address
      // reads what is stored, and would drop it. What was saved is stored by
      // now, whether or not this page has heard so yet.
      if (widget.collectionId == 'new' && !_dirty) {
        // Saved, it is a collection like any other and is at its own address,
        // so that reloading it or keeping it opens this collection rather than
        // a new empty one.
        context.router.replace(
          CollectionDetailRoute(collectionId: _collectionId),
        );
      }
    } catch (error) {
      if (mounted) _say('The collection could not be saved: $error');
    }
  }

  /// Back to reading the collection, as for a set: what has been typed is
  /// saved first, and a save that did not go through leaves it open.
  Future<void> _stopEditing() async {
    if (_dirty) await _save();
    if (!mounted || _dirty) return;
    setState(() => _editing = false);
  }

  /// Opens one piece of the collection the way a score opens from the list of
  /// scores — its details, with the score beside them — read the way the
  /// collection says.
  void _open(CollectionEntry entry) {
    context.router.push(
      ScoreRoute(
        scoreId: entry.scoreId,
        collectionId: _collectionId,
        entryId: entry.id,
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this collection?'),
        content: const Text('The scores in it stay where they are.'),
        actions: [
          KeepButton(onPressed: () => Navigator.of(context).pop(false)),
          ConfirmDeleteButton(
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      (await GetIt.I<DeleteCollection>()(_collectionId)).orThrow();
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
    String? description,
    int? transposition,
  }) async {
    try {
      (await GetIt.I<SaveCollectionEntry>()(
        SaveCollectionEntryParams(
          collectionId: _collectionId,
          id: id,
          scoreId: scoreId,
          description: description,
          transposition: transposition,
        ),
      )).orThrow();
    } on ScoreAlreadyInCollectionException catch (already) {
      // Adding a piece that is here is being shown where it is. Changing one
      // that is here twice is not something scrolling answers: what was typed
      // was not kept, and the player has to be told.
      if (id != null && mounted) {
        _say(
          'That piece is in the collection twice; take one of the two'
          ' out before changing it.',
        );
      }
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

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(message));
  }

  String _stateOf(Collection? collection) {
    if (!_isOwner) {
      // Not read-only: what is in it is theirs, but how you read it is yours.
      return 'shared with you';
    }
    if (_dirty) return 'not saved';
    if (collection == null) return 'new collection';
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

  Widget _entries(Collection? collection, bool owner) {
    final entries = CollectionEntry.sortByTitle(
      collection?.entries ?? const <CollectionEntry>[],
      (scoreId) => _scores.getScore(scoreId)?.title,
    );
    _entryKeys.removeWhere((id, _) => !entries.any((entry) => entry.id == id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In this collection',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!_isStored)
          const Text(
            'Save the collection first. What is in it is stored piece by'
            ' piece, so there has to be a collection to put them in.',
          )
        else if (entries.isEmpty)
          const Text(
            'Nothing in this collection yet. Add the pieces that'
            ' belong in it below.',
          )
        else
          for (final entry in entries)
            _EntryCard(
              key: _entryKeys.putIfAbsent(entry.id, GlobalKey.new),
              entry: entry,
              collectionId: _collectionId,
              owner: owner,
              pointedAt: _pointedAt == entry.id,
              score: _scores.getScore(entry.scoreId),
              onDescription: (text) =>
                  _writeEntry(id: entry.id, description: text),
              onGroupTransposition: (semitones) =>
                  _writeEntry(id: entry.id, transposition: semitones),
              onRemove: () async {
                try {
                  (await GetIt.I<DeleteCollectionEntry>()(
                    DeleteCollectionEntryParams(
                      collectionId: _collectionId,
                      entryId: entry.id,
                    ),
                  )).orThrow();
                } catch (error) {
                  if (mounted) {
                    _say(
                      'That piece could not be taken out of the'
                      ' collection: $error',
                    );
                  }
                }
              },
            ),
      ],
    );
  }

  Widget _picker(Collection? collection) {
    final needle = _filter.text.trim();
    final scores =
        _scores.scores.where((score) => score.matches(needle)).toList()
          ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a piece', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ScoreSearchField(controller: _filter),
        const SizedBox(height: 8),
        if (_scores.scores.isEmpty)
          const Text(
            'No scores on this device to add. They arrive with the'
            ' next sync.',
          )
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
        SharedWithField(
          controller: _sharedWith,
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => _page(context),
    );
  }

  Widget _page(BuildContext context) {
    // TODO: use ValueListenableBuilder
    if (_auth.value?.isScoreViewer != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection')),
        body: const Center(
          child: Text(
            'Collections are for score viewers, and this account is not one.',
          ),
        ),
      );
    }

    // The titles the pieces are listed by are in the scores, so a list of
    // them is drawn again when the scores change as well as when the
    // collection does.
    return UnsavedChangesGuard(
      unsaved: _dirty,
      child: ListenableBuilder(
        listenable: Listenable.merge([_collections, _scores]),
        builder: (context, _) {
          final collection = _stored;
          final owner = _isOwner;
          final editing = owner && _editing;

          // A collection asked for by its id that the sync could not bring in —
          // the device is offline, or it is not shared with this user — is not a
          // new one to be written under that id. Saved, it would be sent over the
          // one the server has, with none of its description or its shares.
          if (!_loading && widget.collectionId != 'new' && collection == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Collection')),
              body: _NotOnThisDevice(onRetry: _retry),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(collection?.displayTitle ?? 'New collection'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: Text(_stateOf(collection))),
                ),
                if (editing) SaveButton(onPressed: _dirty ? _save : null),
                if (editing && _isStored)
                  IconButton(
                    tooltip: 'Done changing it',
                    icon: const Icon(Icons.check),
                    onPressed: _stopEditing,
                  ),
                if (owner && !editing)
                  IconButton(
                    tooltip: 'Change the collection',
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : !editing && collection != null
                ? _CollectionOverview(
                    collection: collection,
                    owner: owner,
                    scoreOf: _scores.getScore,
                    onOpen: _open,
                  )
                // Laid out whole rather than as the list scrolls: the piece a
                // player is pointed at (see _pointAt) has to be on the page to
                // be scrolled to, and with a long list of scores to pick from
                // below it, the pieces above can be scrolled out of a lazy one.
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _about(owner),
                        const SizedBox(height: 24),
                        _entries(collection, owner),
                        const SizedBox(height: 24),
                        if (owner && _isStored) _picker(collection),
                        if (owner) ...[
                          const SizedBox(height: 24),
                          _sharing(),
                          const SizedBox(height: 32),
                          if (_isStored)
                            DeleteCollectionButton(onPressed: _delete),
                        ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// A collection to read and play from: what it is, and the pieces in it by
/// title, each a tap away from the stand.
class const _CollectionOverview({
  required final Collection collection,
  required final bool owner,
  required final Score? Function(String scoreId) scoreOf,
  required final void Function(CollectionEntry entry) onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // By title, the way the stand goes through it: a collection has no order
    // of its own, and a book is looked through by what the pieces are called.
    final entries = CollectionEntry.sortByTitle(
      collection.entries,
      (scoreId) => scoreOf(scoreId)?.title,
    );
    final description = collection.description.trim();

    // Looked through the way the list of every score is — the same search,
    // the same filters — so that finding a piece in the book goes the way
    // finding it on the shelf does.
    final entryOfScore = <String, CollectionEntry>{};
    final scores = <Score>[];
    final unlisted = <CollectionEntry>[];
    for (final entry in entries) {
      final score = scoreOf(entry.scoreId);
      if (score == null) {
        unlisted.add(entry);
      } else {
        entryOfScore[score.id] = entry;
        scores.add(score);
      }
    }

    return ScoreLibrary(
      scores: scores,
      noteOf: (score) => _noteOf(entryOfScore[score.id]!),
      onScoreTapped: (score) => onOpen(entryOfScore[score.id]!),
      empty: entries.isNotEmpty
          ? ''
          : owner
          ? 'Nothing in this collection yet. Change the collection to add'
                ' pieces, or add them from the list of scores.'
          : 'Nothing in this collection yet.',
      header: [
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Text(description),
          ),
        ...unlisted.map(
          (entry) => _OverviewRow(
            entry: entry,
            score: null,
            onTap: () => onOpen(entry),
          ),
        ),
      ],
      footer: [
        if (owner && collection.sharedWith.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shared with', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(collection.sharedWith.join(', ')),
              ],
            ),
          ),
      ],
    );
  }
}

/// What the collection says next to a piece, and the key the group plays it
/// in.
String _noteOf(CollectionEntry entry) {
  final group = entry.transposition;
  return [
    if (entry.description.trim().isNotEmpty) entry.description.trim(),
    if (group != 0) 'group ${group > 0 ? '+' : ''}$group',
  ].join(' · ');
}

/// One piece of the collection, as it is read: which piece, what the
/// collection says next to it, and the key the group plays it in.
class const _OverviewRow({
  required final CollectionEntry entry,
  required final Score? score,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = TextStyle(
      color: theme.colorScheme.outline,
      fontStyle: FontStyle.italic,
    );
    final note = entry.description.trim();
    final group = entry.transposition;

    final title = switch (score) {
      final score? => Text(score.title),
      null => Tooltip(
        message: entry.scoreId,
        child: Text('Not on this device yet', style: muted),
      ),
    };
    final details = [
      if (note.isNotEmpty) note,
      if (group != 0) 'group ${group > 0 ? '+' : ''}$group',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: title,
        subtitle: details.isEmpty ? null : Text(details),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}

/// What is shown for a collection this device does not have and could not
/// fetch.
class const _NotOnThisDevice({
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This collection is not on this device, and the server could not'
              ' be asked for it — or it has not been shared with you.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// One piece of the collection: what it is, how the group plays it, and how
/// this player reads it.
class const _EntryCard({
  super.key,
  required final CollectionEntry entry,
  required final String collectionId,
  required final bool owner,

  /// Whether this is the piece that was just asked for again, and is lit.
  required final bool pointedAt,
  required final Score? score,
  required final void Function(String description) onDescription,
  required final void Function(int semitones) onGroupTransposition,
  required final Future<void> Function() onRemove,
}) extends StatelessWidget {
  /// Stores how this player reads the piece. What is not said is kept as it
  /// is: [SaveCollectionEntryView] writes a view whole, filling in what was left out.
  Future<void> _saveMyView(
    BuildContext context, {
    int? transposition,
    List<String>? hiddenParts,
  }) async {
    try {
      (await GetIt.I<SaveCollectionEntryView>()(
        SaveCollectionEntryViewParams(
          collectionId: collectionId,
          entryId: entry.id,
          transposition: transposition,
          hiddenParts: hiddenParts,
        ),
      )).orThrow();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar('How you read this one could not be saved: $error'),
        );
      }
    }
  }

  Widget _name(ThemeData theme) {
    final muted = TextStyle(
      color: theme.colorScheme.outline,
      fontStyle: FontStyle.italic,
    );
    return switch (score) {
      final score? => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(score.title, style: theme.textTheme.titleSmall),
          // A book is looked through by who wrote what is in it as much as
          // by what it is called.
          if (score.creatorNames.isNotEmpty)
            Text(
              score.creatorNames.join(', '),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      null => Tooltip(
        message: entry.scoreId,
        child: Text('Not on this device yet', style: muted),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final read = entry.combinedTransposition;
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
                // Straight to the music. Opening a piece of a collection is
                // opening it to play it, not to read who wrote it.
                OpenCollectionEntryButton(
                  onPressed: () => context.router.push(
                    ScoreRoute(
                      scoreId: entry.scoreId,
                      collectionId: collectionId,
                      entryId: entry.id,
                    ),
                  ),
                ),
                if (owner) RemoveCollectionEntryButton(onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            CollectionEntryDescriptionField(
              initialValue: entry.description,
              enabled: owner,
              onSubmitted: onDescription,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semitones(
                  label: 'all',
                  tooltip:
                      'The key this one is played in, counted in'
                      ' semitones from where it is written. Everyone sees'
                      ' this.',
                  value: entry.transposition,
                  enabled: owner,
                  onChanged: onGroupTransposition,
                ),
                const Text('+'),
                Semitones(
                  label: 'me',
                  tooltip:
                      'How far you read it on top of that, again in'
                      ' semitones. Only you see this.',
                  value: entry.view.transposition,
                  enabled: true,
                  onChanged: (semitones) =>
                      _saveMyView(context, transposition: semitones),
                ),
                Tooltip(
                  message:
                      'What the two of them come to: the key this one'
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

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_search_field.dart';
import 'package:score/features/sets/behaviours/delete_set.dart';
import 'package:score/features/sets/behaviours/delete_set_entry.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/save_set_entry.dart';
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/widgets/add_score_chip.dart';
import 'package:score/features/sets/widgets/delete_set_button.dart';
import 'package:score/features/sets/widgets/entry_description_field.dart';
import 'package:score/features/sets/widgets/move_entry_down_button.dart';
import 'package:score/features/sets/widgets/move_entry_up_button.dart';
import 'package:score/features/sets/widgets/open_score_button.dart';
import 'package:score/features/sets/widgets/remove_entry_button.dart';
import 'package:score/features/sets/widgets/set_description_field.dart';
import 'package:score/features/sets/widgets/set_title_field.dart';
import 'package:score/router.dart';
import 'package:score/widgets/add_paper_entry_button.dart';
import 'package:score/widgets/confirm_delete_button.dart';
import 'package:score/widgets/error_snack_bar.dart';
import 'package:score/widgets/keep_button.dart';
import 'package:score/widgets/paper_entry_field.dart';
import 'package:score/widgets/save_button.dart';
import 'package:score/widgets/semitones.dart';
import 'package:score/widgets/shared_with_field.dart';
import 'package:score/widgets/show_all_parts_button.dart';
import 'package:score/widgets/unsaved_changes_guard.dart';
import 'package:uuid/uuid.dart';

/// One set, written.
///
/// What the set *is* — the gig, and who may read it — waits for the save
/// button. What is *played* in it does not: an entry is a resource of its own,
/// so adding a song, taking one out, moving one and changing its key each land
/// as they are made. There is nothing to save afterwards, and nothing to lose
/// by leaving the page.
@RoutePage()
class const SetDetailPage({
  super.key,

  /// `new` for a set that has not been saved yet.
  @PathParam('setId') required final String setId,
}) extends StatefulWidget {
  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  final _auth = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();
  final _sets = GetIt.I<SetsNotifier>();

  static const _uuid = Uuid();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sharedWith = TextEditingController();
  final _filter = TextEditingController();
  final _paperEntry = TextEditingController();
  final _paperEntryFocus = FocusNode();

  late String _setId;

  /// Whether what has been typed says something the stored set does not.
  bool _dirty = false;

  /// Whether the set is open to be changed, rather than to be read and played
  /// from. Only ever for its owner.
  ///
  /// Read is what a set is opened as: on the day of the gig it is a running
  /// order to play from, and a page full of fields and arrows is one a thumb
  /// moves a song with by accident. A new set and an empty one open to be
  /// changed instead — there is nothing to read in either, and the first
  /// thing done with one is putting songs in it.
  bool _editing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setId = widget.setId == 'new' ? _uuid.v4() : widget.setId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _sets.removeListener(_takeStoredChanges);
    _title.dispose();
    _description.dispose();
    _sharedWith.dispose();
    _filter.dispose();
    _paperEntry.dispose();
    _paperEntryFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // A set this device has is drawn from what it has, network or no network.
    // One it has never heard of is asked about first: a link into a set can be
    // followed on a device that has not synced since it was shared, and drawing
    // an empty set to type over would be a lie about what is stored under that
    // id.
    if (widget.setId != 'new' && _sets.getSet(_setId) == null) {
      await GetIt.I<SyncSets>()();
    }

    if (!mounted) return;
    _readFromStored();
    final stored = _sets.getSet(_setId);
    setState(() {
      _loading = false;
      _editing =
          widget.setId == 'new' ||
          (stored != null && stored.isOwner && stored.entries.isEmpty);
    });

    _sets.addListener(_takeStoredChanges);

    await GetIt.I<SyncScores>()();
    if (widget.setId != 'new') {
      await GetIt.I<SyncSets>()();
    }
    if (mounted && !_dirty) {
      _readFromStored();
      setState(() {});
    }
  }

  /// Asks the server for the set again, for a page that found it was not here.
  Future<void> _retry() async {
    setState(() => _loading = true);
    await GetIt.I<SyncSets>()();
    if (!mounted) return;
    setState(() {
      _readFromStored();
      _loading = false;
    });
  }

  /// What a sync or another page stored for this set is what the fields show,
  /// for as long as nothing is being typed into them: fields that went on
  /// showing what the set was would be sent back by the next save, over it.
  void _takeStoredChanges() {
    if (!mounted || _dirty) return;
    setState(_readFromStored);
  }

  void _readFromStored() {
    final set = _sets.getSet(_setId);
    // Only what differs is written: writing a field puts its cursor at the end.
    void show(TextEditingController field, String text) {
      if (field.text != text) field.text = text;
    }

    show(_title, set?.title ?? '');
    show(_description, set?.description ?? '');
    show(_sharedWith, (set?.sharedWith ?? const []).join('\n'));
    _dirty = false;
  }

  ScoreSet? get _stored => _sets.getSet(_setId);

  bool get _isOwner => _stored?.isOwner ?? true;

  bool get _isStored => _stored != null;

  Future<void> _save() async {
    final title = _title.text;
    final description = _description.text;
    final sharedWith = _sharedWith.text;
    try {
      (await GetIt.I<SaveSet>()(
        SaveSetParams(
          id: _setId,
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
      if (widget.setId == 'new' && !_dirty) {
        // Saved, it is a set like any other and is at its own address, so that
        // reloading it or keeping it opens this set rather than a new empty
        // one.
        context.router.replace(SetDetailRoute(setId: _setId));
      }
    } catch (error) {
      if (mounted) _say('The set could not be saved: $error');
    }
  }

  /// Back to reading the set. What has been typed into its title, its
  /// description or who it is shared with is saved first; a save that did not
  /// go through leaves the set open, with what was typed still there.
  Future<void> _stopEditing() async {
    if (_dirty) await _save();
    if (!mounted || _dirty) return;
    setState(() => _editing = false);
  }

  /// Plays the set from its first song.
  void _playFrom(SetEntry entry) {
    final scoreId = entry.scoreId;
    context.router.push(
      scoreId == null
          ? paperRoute(setId: _setId, entryId: entry.id)
          : PerformScoreRoute(
              scoreId: scoreId,
              setId: _setId,
              entryId: entry.id,
            ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this set?'),
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
      (await GetIt.I<DeleteSet>()(_setId)).orThrow();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _say('The set could not be deleted: $error');
    }
  }

  Future<void> _writeEntry({
    String? id,
    String? scoreId,
    String? description,
    int? transposition,
    int? position,
  }) async {
    try {
      (await GetIt.I<SaveSetEntry>()(
        SaveSetEntryParams(
          setId: _setId,
          id: id,
          scoreId: scoreId,
          description: description,
          transposition: transposition,
          position: position,
        ),
      )).orThrow();
    } catch (error) {
      if (mounted) {
        _say('That song could not be written into the set: $error');
      }
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(message));
  }

  String _stateOf(ScoreSet? set) {
    if (!_isOwner) {
      return 'shared with you';
    }
    if (_dirty) return 'not saved';
    if (set == null) return 'new set';
    return 'saved';
  }

  Widget _about(bool owner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetTitleField(
          controller: _title,
          enabled: owner,
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        SetDescriptionField(
          controller: _description,
          enabled: owner,
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }

  Widget _entries(ScoreSet? set, bool owner) {
    final entries = set?.entries ?? const <SetEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Played in this order',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!_isStored)
          const Text(
            'Save the set first. What is played in it is stored song by song,'
            ' so there has to be a set to put them in.',
          )
        else if (entries.isEmpty)
          const Text(
            'Nothing in this set yet. Add the scores that are played'
            ' below.',
          )
        else
          for (var index = 0; index < entries.length; index++)
            _EntryCard(
              key: ValueKey(entries[index].id),
              entry: entries[index],
              index: index,
              count: entries.length,
              setId: _setId,
              owner: owner,
              score: switch (entries[index].scoreId) {
                final scoreId? => _scores.getScore(scoreId),
                null => null,
              },
              onMove: (to) => _writeEntry(id: entries[index].id, position: to),
              onDescription: (text) =>
                  _writeEntry(id: entries[index].id, description: text),
              onBandTransposition: (semitones) =>
                  _writeEntry(id: entries[index].id, transposition: semitones),
              onRemove: () async {
                try {
                  (await GetIt.I<DeleteSetEntry>()(
                    DeleteSetEntryParams(
                      setId: _setId,
                      entryId: entries[index].id,
                    ),
                  )).orThrow();
                } catch (error) {
                  if (mounted) _say('That song could not be taken out: $error');
                }
              },
            ),
      ],
    );
  }

  Widget _picker() {
    final needle = _filter.text.trim();
    final scores =
        _scores.scores.where((score) => score.matches(needle)).toList()
          ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a score', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ScoreSearchField(
          controller: _filter,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (scores.isEmpty)
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
                // It goes at the end, which is where a song being added to a
                // gig goes.
                AddScoreChip(
                  title: score.title,
                  onPressed: () => _writeEntry(scoreId: score.id),
                ),
            ],
          ),
        const SizedBox(height: 16),
        // Not everything a band plays has been scanned, and a set that could
        // only hold what has is not the gig.
        const Text(
          'Or a song played from paper. What you write is what the band sees'
          ' in the running order; it may be left empty.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PaperEntryField(
                controller: _paperEntry,
                focusNode: _paperEntryFocus,
                hintText: 'Encore — from the folder',
                onChanged: (_) {},
                onSubmitted: (_) => _addPaperEntry(),
              ),
            ),
            const SizedBox(width: 8),
            AddPaperEntryButton(onPressed: _addPaperEntry),
          ],
        ),
      ],
    );
  }

  /// Puts a song played from paper at the end of the set: named by what was
  /// typed, or not named at all.
  Future<void> _addPaperEntry() async {
    final description = _paperEntry.text.trim();
    _paperEntry.clear();
    await _writeEntry(description: description);
    if (mounted) _paperEntryFocus.requestFocus();
  }

  Widget _sharing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shared with', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'One address per line. Everyone here can read the set and play from'
          ' it; changing it stays yours.',
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
    if (_auth.value?.isScoreViewer != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set')),
        body: const Center(
          child: Text(
            'Sets are for score viewers, and this account is not one.',
          ),
        ),
      );
    }

    return UnsavedChangesGuard(
      unsaved: _dirty,
      child: ListenableBuilder(
        listenable: _sets,
        builder: (context, _) {
          final set = _stored;
          final owner = _isOwner;
          final editing = owner && _editing;

          // A set asked for by its id that the sync could not bring in — the
          // device is offline, or the set is not shared with this user — is not
          // a new set to be written under that id. Saved, it would be sent over
          // the one the server has, with none of its description or its shares.
          if (!_loading && widget.setId != 'new' && set == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Set')),
              body: _NotOnThisDevice(onRetry: _retry),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(set?.displayTitle ?? 'New set'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: Text(_stateOf(set))),
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
                    tooltip: 'Change the set',
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : !editing && set != null
                ? _SetOverview(
                    set: set,
                    owner: owner,
                    scoreOf: _scores.getScore,
                    onPlay: _playFrom,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _about(owner),
                      const SizedBox(height: 24),
                      _entries(set, owner),
                      const SizedBox(height: 24),
                      if (owner && _isStored) _picker(),
                      if (owner) ...[
                        const SizedBox(height: 24),
                        _sharing(),
                        const SizedBox(height: 32),
                        if (_isStored) DeleteSetButton(onPressed: _delete),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// A set to read and play from: what the gig is, and its running order, each
/// song a tap away from the stand.
class const _SetOverview({
  required final ScoreSet set,
  required final bool owner,
  required final Score? Function(String scoreId) scoreOf,
  required final void Function(SetEntry entry) onPlay,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = set.entries;
    final description = set.description.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (description.isNotEmpty) ...[
          Text(description),
          const SizedBox(height: 16),
        ],
        if (entries.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => onPlay(entries.first),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play from the start'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Played in this order', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              owner
                  ? 'Nothing in this set yet. Change the set to add the scores'
                        ' that are played, or add them from the list of scores.'
                  : 'Nothing in this set yet.',
            ),
          )
        else
          for (final (index, entry) in entries.indexed)
            _OverviewRow(
              position: index + 1,
              entry: entry,
              score: switch (entry.scoreId) {
                final scoreId? => scoreOf(scoreId),
                null => null,
              },
              onTap: () => onPlay(entry),
            ),
        if (owner && set.sharedWith.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Shared with', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(set.sharedWith.join(', ')),
        ],
      ],
    );
  }
}

/// One song of the running order, as it is read: which song, what the set
/// says next to it, and the key the band plays it in.
class const _OverviewRow({
  required final int position,
  required final SetEntry entry,
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
    final band = entry.transposition;
    final details = [
      if (entry.description.trim().isNotEmpty) entry.description.trim(),
      if (band != 0) 'band ${band > 0 ? '+' : ''}$band',
    ].join(' · ');

    // A card of its own, with room inside it, the way a score is in the list
    // of scores: a row that runs to the edges of the page has nothing to show
    // where it can be tapped.
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: SizedBox(
          width: 28,
          child: Text('$position.', style: theme.textTheme.labelLarge),
        ),
        title: switch ((entry.scoreId, score)) {
          (_, final score?) => Text(score.title),
          (null, _) => Text('Played from paper', style: muted),
          (final scoreId?, _) => Tooltip(
            message: scoreId,
            child: Text('Not on this device yet', style: muted),
          ),
        },
        subtitle: details.isEmpty ? null : Text(details),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}

/// What is shown for a set this device does not have and could not fetch.
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
              'This set is not on this device, and the server could not be'
              ' asked for it — or it has not been shared with you.',
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

/// One song of the set: what it is, how the band plays it, and how this player
/// reads it.
class const _EntryCard({
  super.key,
  required final SetEntry entry,
  required final int index,
  required final int count,
  required final String setId,
  required final bool owner,
  required final Score? score,
  required final void Function(int position) onMove,
  required final void Function(String description) onDescription,
  required final void Function(int semitones) onBandTransposition,
  required final Future<void> Function() onRemove,
}) extends StatelessWidget {
  Future<void> _saveMyView(
    BuildContext context, {
    required int transposition,
    required List<String> hiddenParts,
  }) async {
    try {
      (await GetIt.I<SaveSetEntryView>()(
        SaveSetEntryViewParams(
          setId: setId,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final read = entry.combinedTransposition;
    final sum = entry.transposition + entry.view.transposition;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${index + 1}.', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: switch ((entry.scoreId, score)) {
                    (_, final score?) => Text(
                      score.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    (null, _) => Text(
                      'Played from paper',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    (final scoreId?, _) => Tooltip(
                      message: scoreId,
                      child: Text(
                        'Not on this device yet',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  },
                ),
                OpenScoreButton(
                  onPressed: switch (entry.scoreId) {
                    final scoreId? => () => context.router.push(
                      PerformScoreRoute(
                        scoreId: scoreId,
                        setId: setId,
                        entryId: entry.id,
                      ),
                    ),
                    // A song with no score opens all the same, as the song it
                    // is in the running order, with the way on to the next.
                    null => () => context.router.push(
                      paperRoute(setId: setId, entryId: entry.id),
                    ),
                  },
                ),
                if (owner) ...[
                  MoveEntryUpButton(
                    onPressed: index == 0 ? null : () => onMove(index - 1),
                  ),
                  MoveEntryDownButton(
                    onPressed: index == count - 1
                        ? null
                        : () => onMove(index + 1),
                  ),
                  RemoveEntryButton(onPressed: onRemove),
                ],
              ],
            ),
            const SizedBox(height: 8),
            EntryDescriptionField(
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
                  label: 'band',
                  tooltip:
                      'The key the band plays this one in, counted in'
                      ' semitones from where it is written. Everyone sees this.',
                  value: entry.transposition,
                  enabled: owner,
                  onChanged: onBandTransposition,
                ),
                const Text('+'),
                Semitones(
                  label: 'me',
                  tooltip:
                      'How far you read it on top of the band, again in'
                      ' semitones. Only you see this.',
                  value: entry.view.transposition,
                  enabled: true,
                  onChanged: (semitones) => _saveMyView(
                    context,
                    transposition: semitones,
                    hiddenParts: entry.view.hiddenParts,
                  ),
                ),
                Tooltip(
                  message:
                      'What the two of them come to: the key this one opens'
                      ' at for you.',
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
                    onPressed: () => _saveMyView(
                      context,
                      transposition: entry.view.transposition,
                      hiddenParts: const [],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../domains/scores/models.dart';
import '../domains/sets/models.dart';
import '../domains/sets/repository.dart';
import '../notation/view/score_view.dart';
import 'routes.dart';

/// One set, written.
///
/// What the set *is* — the gig, and who may read it — waits for the save
/// button. What is *played* in it does not: an entry is a resource of its own,
/// so adding a song, taking one out, moving one and changing its key each land
/// as they are made. There is nothing to save afterwards, and nothing to lose
/// by leaving the page.
class SetDetailPage extends StatefulWidget {
  const SetDetailPage({super.key, required this.setId});

  /// `new` for a set that has not been saved yet.
  final String setId;

  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  static const _uuid = Uuid();

  late String _setId;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sharedWith = TextEditingController();
  final _filter = TextEditingController();

  /// Whether what has been typed says something the stored set does not.
  bool _dirty = false;
  bool _loading = true;

  void Function(SyncProblem)? _problemListener;

  @override
  void initState() {
    super.initState();
    _setId = widget.setId == 'new' ? _uuid.v4() : widget.setId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    final listener = _problemListener;
    if (listener != null) {
      AppScope.read(context).sets.removeSyncProblemListener(listener);
    }
    _title.dispose();
    _description.dispose();
    _sharedWith.dispose();
    _filter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);

    // A set this device has is drawn from what it has, network or no network.
    // One it has never heard of is asked about first: a link into a set can be
    // followed on a device that has not synced since it was shared, and drawing
    // an empty set to type over would be a lie about what is stored under that
    // id.
    if (widget.setId != 'new' && app.sets.getSet(_setId) == null) {
      await app.updateSets();
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
          '"${problem.title.isEmpty ? 'A set' : problem.title}" could not be'
          ' saved on the server (${problem.action}), and the change has been'
          ' taken back: ${problem.error.detail}',
        ),
      ));
      if (problem.setId == _setId && !_dirty) {
        _readFromStored();
        setState(() {});
      }
    };
    app.sets.addSyncProblemListener(_problemListener!);

    await app.updateScores();
    if (widget.setId != 'new') {
      await app.updateSets();
    }
    if (mounted && !_dirty) {
      _readFromStored();
      setState(() {});
    }
  }

  void _readFromStored() {
    final set = AppScope.read(context).sets.getSet(_setId);
    _title.text = set?.title ?? '';
    _description.text = set?.description ?? '';
    _sharedWith.text = (set?.sharedWith ?? const []).join('\n');
    _dirty = false;
  }

  ScoreSet? get _stored => AppScope.read(context).sets.getSet(_setId);

  bool get _isOwner => _stored?.isOwner ?? true;

  bool get _isStored => _stored != null;

  Future<void> _save() async {
    final app = AppScope.read(context);
    try {
      await app.sets.saveSet(
        id: _setId,
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
    } catch (error) {
      if (mounted) _say('The set could not be saved: $error');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this set?'),
        content: const Text('The scores in it stay where they are.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AppScope.read(context).sets.deleteSet(_setId);
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
      await AppScope.read(context).sets.saveEntry(
            _setId,
            id: id,
            scoreId: scoreId,
            description: description,
            transposition: transposition,
            position: position,
          );
    } catch (error) {
      if (mounted) {
        _say('That song could not be written into the set: $error');
      }
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.user?.isScoreViewer != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set')),
        body: const Center(
          child: Text('Sets are for score viewers, and this account is not one.'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: app.sets,
      builder: (context, _) {
        final set = _stored;
        final owner = _isOwner;

        return Scaffold(
          appBar: AppBar(
            title: Text(set?.displayTitle ?? 'New set'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text(_stateOf(set))),
              ),
              if (owner)
                TextButton(
                  onPressed: _dirty ? _save : null,
                  child: const Text('Save'),
                ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _about(owner),
                    const SizedBox(height: 24),
                    _entries(app, set, owner),
                    const SizedBox(height: 24),
                    if (owner && _isStored) _picker(app),
                    if (owner) ...[
                      const SizedBox(height: 24),
                      _sharing(),
                      const SizedBox(height: 32),
                      if (_isStored)
                        OutlinedButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete this set'),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  String _stateOf(ScoreSet? set) {
    if (!_isOwner) {
      return set?.owesAnything == true
          ? 'shared with you — your reading is not sent yet'
          : 'shared with you';
    }
    if (_dirty) return 'not saved';
    if (set == null) return 'new set';
    if (set.owesAnything) return 'saved here, not sent yet';
    return 'saved';
  }

  Widget _about(bool owner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _title,
          enabled: owner,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Zomerbar 12 juli',
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          enabled: owner,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'About the gig',
            hintText: 'two sets of forty minutes, break at ten',
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }

  Widget _entries(App app, ScoreSet? set, bool owner) {
    final entries = set?.entries ?? const <SetEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Played in this order',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (!_isStored)
          const Text(
            'Save the set first. What is played in it is stored song by song,'
            ' so there has to be a set to put them in.',
          )
        else if (entries.isEmpty)
          const Text('Nothing in this set yet. Add the scores that are played'
              ' below.')
        else
          for (var index = 0; index < entries.length; index++)
            _EntryCard(
              key: ValueKey(entries[index].id),
              entry: entries[index],
              index: index,
              count: entries.length,
              setId: _setId,
              owner: owner,
              score: app.scores.getScore(entries[index].scoreId),
              onMove: (to) =>
                  _writeEntry(id: entries[index].id, position: to),
              onDescription: (text) =>
                  _writeEntry(id: entries[index].id, description: text),
              onBandTransposition: (semitones) =>
                  _writeEntry(id: entries[index].id, transposition: semitones),
              onRemove: () async {
                try {
                  await app.sets.deleteEntry(_setId, entries[index].id);
                } catch (error) {
                  if (mounted) _say('That song could not be taken out: $error');
                }
              },
            ),
      ],
    );
  }

  Widget _picker(App app) {
    final needle = _filter.text.trim().toLowerCase();
    final scores = app.scores.scores
        .where((score) => needle.isEmpty || score.searchText.contains(needle))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a score', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _filter,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'title, creator or tag',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (scores.isEmpty)
          const Text('No scores on this device to add. They arrive with the'
              ' next sync.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final score in scores)
                ActionChip(
                  label: Text(score.title),
                  // The same score can be played more than once in a gig, each
                  // time with its own key and its own note next to it, so this
                  // adds rather than toggles. It goes at the end, which is where
                  // a song being added to a gig goes.
                  onPressed: () => _writeEntry(scoreId: score.id),
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
          'One address per line. Everyone here can read the set and play from'
          ' it; changing it stays yours.',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sharedWith,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'bas@example.com',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ],
    );
  }
}

/// One song of the set: what it is, how the band plays it, and how this player
/// reads it.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.count,
    required this.setId,
    required this.owner,
    required this.score,
    required this.onMove,
    required this.onDescription,
    required this.onBandTransposition,
    required this.onRemove,
  });

  final SetEntry entry;
  final int index;
  final int count;
  final String setId;
  final bool owner;
  final Score? score;
  final void Function(int position) onMove;
  final void Function(String description) onDescription;
  final void Function(int semitones) onBandTransposition;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final read = entry.readAt;
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
                  child: score == null
                      ? Tooltip(
                          message: entry.scoreId,
                          child: Text('Not on this device yet',
                              style: TextStyle(
                                  color: theme.colorScheme.outline,
                                  fontStyle: FontStyle.italic)),
                        )
                      : Text(score!.title, style: theme.textTheme.titleSmall),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoute.score(entry.scoreId,
                        setId: setId, entryId: entry.id),
                  ),
                  child: const Text('Open'),
                ),
                if (owner) ...[
                  IconButton(
                    tooltip: 'Move up',
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: index == 0 ? null : () => onMove(index - 1),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    icon: const Icon(Icons.arrow_downward),
                    onPressed:
                        index == count - 1 ? null : () => onMove(index + 1),
                  ),
                  IconButton(
                    tooltip: 'Take out of the set',
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: entry.description,
              enabled: owner,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'capo 2, second verse only, straight into the next',
              ),
              // On submitted rather than on changed: every one of these is a
              // write of that song, and a write per keystroke is a write per
              // keystroke.
              onFieldSubmitted: onDescription,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Semitones(
                  label: 'band',
                  tooltip: 'The key the band plays this one in, counted in'
                      ' semitones from where it is written. Everyone sees this.',
                  value: entry.transposition,
                  enabled: owner,
                  onChanged: onBandTransposition,
                ),
                const Text('+'),
                _Semitones(
                  label: 'me',
                  tooltip: 'How far you read it on top of the band, again in'
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
                  message: 'What the two of them come to: the key this one opens'
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
                  TextButton(
                    onPressed: () => _saveMyView(
                      context,
                      transposition: entry.view.transposition,
                      hiddenParts: const [],
                    ),
                    child: const Text('show all'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMyView(
    BuildContext context, {
    required int transposition,
    required List<String> hiddenParts,
  }) async {
    try {
      await AppScope.read(context).sets.saveEntryView(
            setId,
            entry.id,
            transposition: transposition,
            hiddenParts: hiddenParts,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('How you read this one could not be saved:'
              ' $error')),
        );
      }
    }
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
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: enabled && value > minTransposition
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text('${value > 0 ? '+' : ''}$value',
                textAlign: TextAlign.center),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: enabled && value < maxTransposition
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

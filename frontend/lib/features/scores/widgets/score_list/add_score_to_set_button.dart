import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/sets/behaviours/save_set_entry.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/widgets/exceptions.dart';

class const AddScoreToSetButton({
  super.key,
  required final String scoreId,
}) extends StatelessWidget {
  Future<void> onTap(BuildContext context) async {
    final selected = await showDialog<_SetSelection>(
      context: context,
      builder: (context) => const SelectSetDialog(),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    switch (selected) {
      case _NewSet():
        break;
      case _ExistingSet(setId: final setId):
        await addScoreToSet(context, setId);
    }
  }

  Future<void> addScoreToSet(BuildContext context, String setId) async {
    final result = await GetIt.I<SaveSetEntry>()(
      SaveSetEntryParams(setId: setId, scoreId: scoreId),
    );
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success():
        return;
      case Failed<ScoreSet>(reason: final exception):
        await showExceptionDialog(
          context,
          title: 'Failed to add the score to the set',
          message: exception.toString(),
        );
    }
  }

  Future<void> createNewSet(BuildContext context) async {
    // TODO navigate to create set page with one initial score
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Add to a set',
      icon: const Icon(Icons.playlist_add),
      onPressed: () => onTap(context),
    );
  }
}

class const SelectSetDialog({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Add to which set?'),
      children: [
        ValueListenableBuilder(
          valueListenable: GetIt.I<SetsNotifier>(),
          builder: (context, sets, _) => Column(
            children: [
              for (final set in sets.where((set) => set.isOwner))
                SimpleDialogOption(
                  onPressed: () =>
                      Navigator.of(context).pop(_ExistingSet(set.id)),
                  child: Text(set.title),
                ),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(const _NewSet()),
          child: const Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('A new set…'),
            ],
          ),
        ),
      ],
    );
  }
}

sealed class const _SetSelection() {}

class const _ExistingSet(final String setId) extends _SetSelection {}

class const _NewSet() extends _SetSelection {}

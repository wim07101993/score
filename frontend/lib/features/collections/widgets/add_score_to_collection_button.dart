import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/collections/behaviours/save_collection_entry.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/widgets/exceptions.dart';

class const AddScoreToCollectionButton({
  super.key,
  required final String scoreId,
}) extends StatelessWidget {
  Future<void> onTap(BuildContext context) async {
    final selected = await showDialog<_CollectionSelection>(
      context: context,
      builder: (context) => const SelectCollectionDialog(),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    switch (selected) {
      case _NewCollection():
        break;
      case _ExistingCollection(collectionId: final collectionId):
        await addScoreToCollection(context, collectionId);
    }
  }

  Future<void> addScoreToCollection(
    BuildContext context,
    String collectionId,
  ) async {
    final result = await GetIt.I<SaveCollectionEntry>()(
      SaveCollectionEntryParams(
        collectionId: collectionId,
        scoreId: scoreId,
      ),
    );
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success<Collection>():
        return;
      case Failed(reason: final exception):
        await showExceptionDialog(
          context,
          title: 'Failed to add the score to the collection',
          message: exception.toString(),
        );
    }
  }

  Future<void> createNewCollection(BuildContext context) async {
    // TODO navigate to create set page with one initial score
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Add to a collection',
      icon: const Icon(Icons.library_add_outlined),
      onPressed: () => onTap(context),
    );
  }
}

class const SelectCollectionDialog({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Add to which collection?'),
      children: [
        ValueListenableBuilder(
          valueListenable: GetIt.I<CollectionsNotifier>(),
          builder: (context, collections, _) {
            final owningCollections = collections.where(
              (collection) => collection.isOwner,
            );
            return Column(
              children: [
                for (final collection in owningCollections)
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(_ExistingCollection(collection.id));
                    },
                    child: Text(collection.title),
                  ),
              ],
            );
          },
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(const _NewCollection()),
          child: const Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('A new collection…'),
            ],
          ),
        ),
      ],
    );
  }
}

sealed class const _CollectionSelection() {}

class const _ExistingCollection(final String collectionId)
    extends _CollectionSelection {}

class const _NewCollection() extends _CollectionSelection {}

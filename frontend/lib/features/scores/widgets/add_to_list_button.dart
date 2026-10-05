import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sets/repository.dart';
import 'package:score/router.dart';
import 'package:score/widgets/error_snack_bar.dart';

/// Puts a score into one of this player's sets or collections, from wherever
/// the score is — the list of scores, mostly, which is where a player is when
/// they think "that one should be in tonight's set".
///
/// It goes on the end of a set, which is where a song being added to a gig
/// goes; a collection has no order for it to go anywhere in. Only the sets and
/// collections that are this player's are offered: one that is only shared
/// with them is not theirs to fill.
class AddToListButtons extends StatelessWidget {
  const AddToListButtons({
    super.key,
    required this.scoreId,
  });

  final String scoreId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Add to a set',
          icon: const Icon(Icons.playlist_add),
          onPressed: () => _addTo(context, _Kind.set),
        ),
        IconButton(
          tooltip: 'Add to a collection',
          icon: const Icon(Icons.library_add_outlined),
          onPressed: () => _addTo(context, _Kind.collection),
        ),
      ],
    );
  }

  Future<void> _addTo(BuildContext context, _Kind kind) async {
    final sets = GetIt.I<SetsRepository>();
    final collections = GetIt.I<CollectionsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final router = context.router;
    final isSet = kind == _Kind.set;

    final owned = isSet
        ? [
            for (final set in sets.sets)
              if (set.isOwner) (id: set.id, title: set.displayTitle),
          ]
        : [
            for (final collection in collections.collections)
              if (collection.isOwner)
                (id: collection.id, title: collection.displayTitle),
          ];

    final picked = await showDialog<_Pick>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(isSet ? 'Add to which set?' : 'Add to which collection?'),
        children: [
          for (final list in owned)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context)
                  .pop(_Pick(id: list.id, title: list.title)),
              child: Text(list.title),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(const _Pick.newOne()),
            child: Row(
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(isSet ? 'A new set…' : 'A new collection…'),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;

    var target = picked;
    if (target.id == null) {
      final title = await _askForTitle(context, isSet: isSet);
      if (title == null) return;
      try {
        final id = isSet
            ? (await sets.saveSet(title: title)).id
            : (await collections.saveCollection(title: title)).id;
        target = _Pick(id: id, title: title);
      } catch (error) {
        messenger.showSnackBar(errorSnackBar(
          'The ${isSet ? 'set' : 'collection'} could not be made: $error',
        ));
        return;
      }
    }
    final id = target.id!;

    void open() => router.push(
          isSet
              ? SetDetailRoute(setId: id)
              : CollectionDetailRoute(collectionId: id),
        );

    try {
      if (isSet) {
        await sets.saveEntry(id, scoreId: scoreId);
      } else {
        await collections.saveEntry(id, scoreId: scoreId);
      }
      messenger.showSnackBar(SnackBar(
        content: Text('Added to "${target.title}".'),
        action: SnackBarAction(label: 'Open', onPressed: open),
      ));
    } on ScoreAlreadyInCollectionException {
      // What was wanted is the piece in the book, and it is.
      messenger.showSnackBar(SnackBar(
        content: Text('It is in "${target.title}" already.'),
        action: SnackBarAction(label: 'Open', onPressed: open),
      ));
    } catch (error) {
      messenger.showSnackBar(errorSnackBar(
        'It could not be added to "${target.title}": $error',
      ));
    }
  }

  /// What a new set or collection is to be called, or null when the player
  /// thought better of it.
  static Future<String?> _askForTitle(
    BuildContext context, {
    required bool isSet,
  }) {
    final field = TextEditingController();
    void done(BuildContext context) {
      final title = field.text.trim();
      if (title.isNotEmpty) Navigator.of(context).pop(title);
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSet ? 'A new set' : 'A new collection'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: isSet ? 'Zomerbar, 14 June' : 'The Real Book',
          ),
          onSubmitted: (_) => done(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => done(context),
            child: const Text('Make it'),
          ),
        ],
      ),
    ).whenComplete(field.dispose);
  }
}

enum _Kind { set, collection }

/// The set or collection picked, or none yet: a new one is to be made.
class _Pick {
  const _Pick({required this.id, required this.title});

  const _Pick.newOne()
      : id = null,
        title = '';

  final String? id;
  final String title;
}

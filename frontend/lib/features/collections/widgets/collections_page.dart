import 'package:flutter/material.dart';
import 'package:score/app.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/routes.dart';

/// The collections there are.
///
/// A collection is a group of scores that belong together without being played
/// in any order: a book they are printed in, or the repertoire of a band.
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({
    super.key,
  });

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final app = AppScope.read(context);
    if (app.user?.isScoreViewer != true) return;

    await app.updateCollections();
    // The scores are what a collection is made of, so one that was written on
    // another device is only readable here once its scores are.
    await app.updateScores();

    final reachable = await app.collectionsApi.canBeReached();
    if (mounted) {
      setState(() => _offline = !reachable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mayView = app.user?.isScoreViewer == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: mayView
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoute.newCollection()),
              icon: const Icon(Icons.add),
              label: const Text('New collection'),
            )
          : null,
      body: !mayView
          ? const Center(child: Text('Collections are for score viewers.'))
          : ListenableBuilder(
              listenable: app.collections,
              builder: (context, _) {
                final collections = app.collections.collections;

                return RefreshIndicator(
                  onRefresh: _sync,
                  child: collections.isEmpty
                      ? ListView(
                          children: [
                            if (_offline) const _OfflineNotice(),
                            const SizedBox(height: 80),
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No collections yet. A collection is a group'
                                ' of scores that belong together without being'
                                ' played in any order: a book they are printed'
                                ' in, or the repertoire of a band you play'
                                ' with.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: collections.length + (_offline ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_offline && index == 0) {
                              return const _OfflineNotice();
                            }
                            final collection =
                                collections[index - (_offline ? 1 : 0)];
                            return _CollectionCard(collection: collection);
                          },
                        ),
                );
              },
            ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'The server cannot be reached. What is here is what this device'
          ' knows; edits are kept and sent as soon as it can be reached again.',
        ),
      ),
    );
  }
}

/// One collection in the list: what the group of pieces is, what it is about,
/// how much is in it, and whether anybody else has it yet.
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
  });

  final Collection collection;

  /// What is worth saying about a collection beyond what it holds: whose it
  /// is, and whether the server has heard about it yet.
  ///
  /// One that is still owed to the server can be read from all the same, which
  /// is the point, but saying so is what keeps "I added that" and "the others
  /// can see it" apart.
  String get _state {
    if (!collection.isOwner) return 'shared with you';
    if (collection.owesAnything) return 'not sent yet';
    if (collection.sharedWith.isNotEmpty) {
      return 'shared with ${collection.sharedWith.length}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = collection.entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .pushNamed(AppRoute.collection(collection.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(collection.displayTitle,
                  style: theme.textTheme.titleMedium),
              if (collection.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(collection.description, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$count piece${count == 1 ? '' : 's'}',
                      style: theme.textTheme.labelMedium),
                  if (_state.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_state),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/auth.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sync/sync.dart';
import 'package:score/router.dart';
import 'package:score/widgets/offline_notice.dart';
import 'package:score/widgets/sync_button.dart';

/// The collections there are.
///
/// A collection is a group of scores that belong together without being played
/// in any order: a book they are printed in, or the repertoire of a band.
@RoutePage()
class const CollectionsPage({
  super.key,
}) extends StatefulWidget {
  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final _auth = GetIt.I<Auth>();
  final _collections = GetIt.I<CollectionsRepository>();

  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final sync = GetIt.I<Sync>();
    if (_auth.user?.isScoreViewer != true) return;

    await sync.updateCollections();
    // The scores are what a collection is made of, so one that was written on
    // another device is only readable here once its scores are.
    await sync.updateScores();

    final reachable = await GetIt.I<CollectionsApi>().canBeReached();
    if (mounted) {
      setState(() => _offline = !reachable);
    }
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
    final mayView = _auth.user?.isScoreViewer == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [if (mayView) const SyncButton()],
      ),
      floatingActionButton: mayView
          ? FloatingActionButton.extended(
              onPressed: () => context.router
                  .push(CollectionDetailRoute(collectionId: 'new')),
              icon: const Icon(Icons.add),
              label: const Text('New collection'),
            )
          : null,
      body: !mayView
          ? const Center(child: Text('Collections are for score viewers.'))
          : ListenableBuilder(
              listenable: _collections,
              builder: (context, _) {
                final collections = _collections.collections;

                return RefreshIndicator(
                  onRefresh: _sync,
                  child: collections.isEmpty
                      ? ListView(
                          children: [
                            if (_offline) const OfflineNotice(),
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
                              return const OfflineNotice();
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

/// One collection in the list: what the group of pieces is, what it is about,
/// how much is in it, and whether anybody else has it yet.
class const _CollectionCard({
  required final Collection collection,
}) extends StatelessWidget {
  /// What is worth saying about a collection beyond what it holds: whose it
  /// is, and whether the server has heard about it yet.
  ///
  /// One that is still owed to the server can be read from all the same, which
  /// is the point, but saying so is what keeps "I added that" and "the others
  /// can see it" apart.
  String get _state {
    if (!collection.isOwner) return 'shared with you';
    if (collection.owesAnything) return 'not synced yet';
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
        onTap: () => context.router
            .push(CollectionDetailRoute(collectionId: collection.id)),
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

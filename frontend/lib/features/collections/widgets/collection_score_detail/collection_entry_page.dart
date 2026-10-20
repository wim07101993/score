import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/widgets/collection_score_detail/collection_score_detail_page.dart';

@RoutePage()
class const CollectionEntryPage({
  super.key,
  @PathParam('collectionId') required final String collectionId,
  @PathParam('entryId') required final String entryId,
  @QueryParam('isPerforming') final bool? isPerforming,
}) extends StatefulWidget {
  @override
  State<CollectionEntryPage> createState() => _CollectionEntryPageState();
}

class _CollectionEntryPageState extends State<CollectionEntryPage> {
  final _collections = GetIt.I<CollectionsNotifier>();

  Collection? _collection;
  bool _reading = true;

  @override
  void initState() {
    super.initState();
    _collections.addListener(_takeCollectionChanges);
    _readCollection();
  }

  @override
  void dispose() {
    _collections.removeListener(_takeCollectionChanges);
    super.dispose();
  }

  Future<void> _readCollection() async {
    final collection = (await GetIt.I<GetCollection>()(
      widget.collectionId,
    )).valueOrNull;
    if (!mounted) return;
    setState(() {
      _collection = collection;
      _reading = false;
    });
  }

  CollectionEntry? _entryOf(Collection? collection) => collection?.entries
      .where((entry) => entry.id == widget.entryId)
      .firstOrNull;

  void _takeCollectionChanges() {
    if (_reading) return;
    final now = _collections.getCollection(widget.collectionId);
    final entry = _entryOf(now);
    final shown = _entryOf(_collection);
    if (entry == null || (shown != null && entry.scoreId == shown.scoreId)) {
      return;
    }
    setState(() => _collection = now);
  }

  @override
  Widget build(BuildContext context) {
    if (_reading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return CollectionScoreDetailPage(
      key: ObjectKey(_collection),
      collection: _collection,
      entryId: widget.entryId,
      isPerforming: widget.isPerforming ?? false,
    );
  }
}

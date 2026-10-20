import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/widgets/collection_score_detail/collection_context.dart';
import 'package:score/features/collections/widgets/collection_score_detail/collection_entry_reading.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_details_body.dart';
import 'package:score/features/scores/widgets/score_detail/reading_keeper.dart';
import 'package:score/features/scores/widgets/score_detail/say.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/scores/widgets/score_detail/scores_are_for_viewers.dart';
import 'package:score/features/scores/widgets/score_detail/stand/immersive_stand.dart';
import 'package:score/features/scores/widgets/score_detail/stand/stand_actions.dart';

class const CollectionScoreDetailPage({
  super.key,
  required final Collection? collection,
  required final String entryId,
  final bool isPerforming = false,
}) extends StatefulWidget {
  @override
  State<CollectionScoreDetailPage> createState() =>
      _CollectionScoreDetailPageState();
}

class _CollectionScoreDetailPageState extends State<CollectionScoreDetailPage> {
  final _user = GetIt.I<AuthNotifier>();
  final _collections = GetIt.I<CollectionsNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  late bool _performing = widget.isPerforming;

  late final _reader = ScoreReader(
    scoreId: _scoreId,
    settings: () => _reading?.onScreen,
  );
  late final _keeper = ReadingKeeper(
    reader: _reader,
    isKept: (onScreen, partIds) =>
        _reading?.isOnScreen(onScreen, partIds: partIds) ?? true,
    save: _saveReading,
    onLetGo: _letGoOfTheEntry,
    say: _say,
  );
  late final AppLifecycleListener _lifecycle;

  late CollectionContext? _collection = switch (widget.collection) {
    final collection?
        when collection.entries.any((entry) => entry.id == widget.entryId) =>
      CollectionContext(collection: collection, entryId: widget.entryId),
    _ => null,
  };
  late final String? _scoreId = _collection?.entry?.scoreId;

  CollectionEntryReading? get _reading => switch (_collection?.entry) {
    final entry? => CollectionEntryReading(entry: entry),
    null => null,
  };

  @override
  void initState() {
    super.initState();
    _reader.open();
    _keeper.start();
    _collections.addListener(_takeCollectionChanges);
    // A tablet put away, or a tab put in the background, may not come back:
    // what the player changed is kept before it goes.
    _lifecycle = AppLifecycleListener(
      onHide: _keeper.keepWhatIsWaiting,
      onPause: _keeper.keepWhatIsWaiting,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reader.load());
  }

  @override
  void dispose() {
    _keeper.dispose();
    _lifecycle.dispose();
    _collections.removeListener(_takeCollectionChanges);
    _reader.dispose();
    super.dispose();
  }

  void _takeCollectionChanges() {
    final context = _collection;
    if (!mounted || context == null) return;
    final latest = _collections.getCollection(context.collection.id);
    if (identical(latest, context.collection)) return;
    final now = context.refreshedFrom(latest);
    final piece = now.entry;
    // Taken out of the collection, or the collection deleted: the score is
    // still worth reading, but there is no reading left to keep against it.
    if (identical(now, context)) {
      _letGoOfTheEntry();
      return;
    }
    if (piece != null && piece.scoreId != _scoreId) {
      _letGoOfTheEntry();
      return;
    }
    setState(() => _collection = now);
    if (piece != null && !_keeper.isPending) {
      _reader.view?.apply(CollectionEntryReading(entry: piece).onScreen);
    }
  }

  void _letGoOfTheEntry() {
    _keeper.cancel();
    setState(() => _collection = null);
    _reader.view?.apply(const ScoreViewSettings.defaultView());
  }

  Future<bool> _saveReading(ScoreViewSettings onScreen) async {
    final context = _collection;
    final entry = context?.entry;
    if (context == null || entry == null) return true;
    final reading = CollectionEntryReading(entry: entry).toSave(onScreen);

    final saved = (await GetIt.I<SaveCollectionEntryView>()(
      SaveCollectionEntryViewParams(
        collectionId: context.collection.id,
        entryId: entry.id,
        transposition: reading.transposition,
        hiddenParts: reading.hiddenParts,
        zoom: reading.zoom,
      ),
    )).orThrow();
    if (!mounted) return true;
    final piece = saved.entries
        .where((piece) => piece.id == entry.id)
        .firstOrNull;
    // Nor is the entry taken back once it has been let go of: a sync that
    // wrote it to play another score while this was on its way has already
    // said this page is not that entry's any more.
    if (_collection == null || (piece != null && piece.scoreId != _scoreId)) {
      return false;
    }
    setState(() {
      _collection = piece != null
          ? CollectionContext(collection: saved, entryId: entry.id)
          : null;
    });
    return true;
  }

  void _say(String message, {bool briefly = false}) {
    if (!mounted) return;
    say(context, message, briefly: briefly);
  }

  void _perform() => setState(() => _performing = true);

  void _stopPerforming(bool didPop, Object? _) {
    if (!didPop) setState(() => _performing = false);
  }

  Score? get _score => switch (_scoreId) {
    final scoreId? => _scores.getScore(scoreId),
    null => null,
  };

  String get _title => _score?.title ?? 'Score';

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: Listenable.merge([
        _user,
        _scores,
        _reader,
      ]),
      builder: (context, _) {
        final user = _user.value;
        final mayView = user != null && user.isScoreViewer;
        final performing = _performing;
        return PopScope(
          canPop: !performing || widget.isPerforming,
          onPopInvokedWithResult: _stopPerforming,
          child: Scaffold(
            appBar: mayView && performing
                ? _standAppBar()
                : AppBar(title: Text(_title)),
            body: !mayView
                ? const ScoresAreForViewers()
                : _scoreId == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'This piece is no longer in there.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                : performing
                ? ImmersiveStand(child: ScoreDetailSheet(reader: _reader))
                : ScoreDetailsBody(
                    reader: _reader,
                    onPerform: _perform,
                    score: _score,
                    user: user,
                    keptAsYourReading: _collection != null,
                  ),
          ),
        );
      },
    );
  }

  AppBar _standAppBar() {
    return AppBar(
      toolbarHeight: 48,
      titleSpacing: 0,
      title: Text(_title, overflow: TextOverflow.ellipsis),
      actions: [
        StandActions(
          controller: _reader.view,
          keptAsYourReading: _collection != null,
        ),
      ],
    );
  }
}

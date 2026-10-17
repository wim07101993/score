import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_details_body.dart';
import 'package:score/features/scores/widgets/score_detail/models/collection_context.dart';
import 'package:score/features/scores/widgets/score_detail/models/entry_reading.dart';
import 'package:score/features/scores/widgets/score_detail/models/score_reading_handover.dart';
import 'package:score/features/scores/widgets/score_detail/reading_keeper.dart';
import 'package:score/features/scores/widgets/score_detail/say.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_page.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/scores/widgets/score_detail/scores_are_for_viewers.dart';
import 'package:score/features/scores/widgets/score_detail/stand/stand_actions.dart';
import 'package:score/features/scores/widgets/score_detail/stand/stand_title.dart';
import 'package:score/features/scores/widgets/score_detail/way/way_through.dart';
import 'package:score/router.dart';

class const CollectionScoreDetailPage({
  super.key,
  required final String scoreId,
  required final String collectionId,
  required final String entryId,
  final bool performing = false,
  final ScoreReadingHandover? handover,
}) extends StatefulWidget {
  @override
  State<CollectionScoreDetailPage> createState() =>
      _CollectionScoreDetailPageState();
}

class _CollectionScoreDetailPageState extends State<CollectionScoreDetailPage> {
  final _user = GetIt.I<AuthNotifier>();
  final _collections = GetIt.I<CollectionsNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  late final _reader = ScoreReader(
    scoreId: _entryScoreId,
    performing: widget.performing,
    handover: widget.handover,
    reading: () => _reading,
  );
  late final _keeper = ReadingKeeper(
    reader: _reader,
    reading: () => _reading,
    save: _saveReading,
    onLetGo: _letGoOfTheEntry,
    say: _say,
  );
  late final AppLifecycleListener _lifecycle;

  CollectionContext? _collection;

  bool get _isPaper => widget.scoreId == ScoreDetailPage.paper;
  String? get _entryScoreId => _isPaper ? null : widget.scoreId;

  EntryReading? get _reading => switch (_collection?.entry) {
    final entry? => EntryReading.ofPiece(entry: entry),
    null => null,
  };

  @override
  void initState() {
    super.initState();
    _reader.open();
    _collections.addListener(_takeCollectionChanges);
    // A tablet put away, or a tab put in the background, may not come back:
    // what the player changed is kept before it goes.
    _lifecycle = AppLifecycleListener(
      onHide: _keeper.keepWhatIsWaiting,
      onPause: _keeper.keepWhatIsWaiting,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reader.load(readEntry: _readEntry),
    );
  }

  @override
  void dispose() {
    _keeper.keepWhatIsWaiting();
    _lifecycle.dispose();
    _collections.removeListener(_takeCollectionChanges);
    _reader.dispose();
    super.dispose();
  }

  Future<void> _readEntry() async {
    final collection = (await GetIt.I<GetCollection>()(
      widget.collectionId,
    )).valueOrNull;
    if (collection == null) return;

    final entry = collection.entries
        .where((candidate) => candidate.id == widget.entryId)
        .firstOrNull;
    // The entry has to be an entry of this score, for the same reason as in a
    // set: the score is what the page is of, so the collection gives way.
    if (entry == null || entry.scoreId != _entryScoreId) return;

    if (!mounted) return;
    setState(() {
      _collection = CollectionContext(
        collection: collection,
        entryId: widget.entryId,
      );
    });
  }

  void _takeCollectionChanges() {
    final context = _collection;
    if (!mounted || context == null) return;
    final latest = _collections.getCollection(context.collection.id);
    if (identical(latest, context.collection)) return;
    final now = context.refreshedFrom(latest);
    final before = context.entry;
    final piece = now.entry;
    // Taken out of the collection, or the collection deleted: the score is
    // still worth reading, but there is no reading left to keep against it.
    if (identical(now, context)) {
      _letGoOfTheEntry();
      return;
    }
    if (piece != null && piece.scoreId != _entryScoreId) {
      _letGoOfTheEntry(scannedAs: piece.scoreId);
      return;
    }
    setState(() => _collection = now);
    if (before != null && piece != null) {
      _reader.takeReading(
        was: EntryReading.ofPiece(entry: before),
        now: EntryReading.ofPiece(entry: piece),
        keepTouched: _keeper.isPending,
      );
    }
  }

  void _letGoOfTheEntry({String? scannedAs}) {
    final collection = _collection;
    if (_isPaper && scannedAs != null && collection != null) {
      context.router.replace(
        scoreRoute(
          scannedAs,
          collectionId: collection.collection.id,
          entryId: collection.entryId,
          performing: widget.performing,
        ),
      );
      return;
    }
    _keeper.cancel();
    setState(() => _collection = null);
    _reader.reset();
  }

  Future<bool> _saveReading({
    required int transposition,
    required List<String> hiddenParts,
    required double zoom,
  }) async {
    final context = _collection;
    final entry = context?.entry;
    if (context == null || entry == null) return true;

    final saved = (await GetIt.I<SaveCollectionEntryView>()(
      SaveCollectionEntryViewParams(
        collectionId: context.collection.id,
        entryId: entry.id,
        transposition: transposition,
        hiddenParts: hiddenParts,
        zoom: zoom,
      ),
    )).orThrow();
    if (!mounted) return true;
    final piece = saved.entries
        .where((piece) => piece.id == entry.id)
        .firstOrNull;
    // Nor is the entry taken back once it has been let go of: a sync that
    // wrote it to play another score while this was on its way has already
    // said this page is not that entry's any more.
    if (_collection == null ||
        (piece != null && piece.scoreId != _entryScoreId)) {
      return false;
    }
    setState(() {
      _collection = piece != null
          ? CollectionContext(collection: saved, entryId: entry.id)
          : null;
    });
    return true;
  }

  /// The way through the collection this is played from.
  ///
  /// The collection is read as it is now rather than as it was when the page
  /// opened: the titles the way through it is sorted by arrive with the
  /// scores, after the page has opened, and a sync can bring in pieces
  /// somebody else put into the book. Which is why whatever draws this
  /// listens to both.
  WayThrough? _wayThrough() {
    final collection = _collection;
    // A collection is a book and not a running order, so its details have
    // no way through it: the piece is looked up, not played after the last.
    // On the stand the pieces either side are still a tap away.
    if (collection == null || !widget.performing) return null;
    return WayThrough.ofCollection(
      collection.refreshedFrom(
        _collections.getCollection(collection.collection.id),
      ),
      titleOf: (scoreId) => _scores.getScore(scoreId)?.title,
      performing: widget.performing,
    );
  }

  void _say(String message, {bool briefly = false}) {
    if (!mounted) return;
    say(context, message, briefly: briefly);
  }

  /// Puts the score on the whole screen, read the way it is being read here.
  ///
  /// What was waiting to be kept is kept first: the stand keeps its own
  /// reading against the same entry, and the two must not cross.
  void _perform() {
    _keeper.keepWhatIsWaiting();
    final collection = _collection;
    context.router.push(
      PerformScoreRoute(
        scoreId: widget.scoreId,
        collectionId: collection?.collection.id,
        entryId: collection?.entryId,
        handover: _reader.handOver(),
      ),
    );
  }

  /// Opens the one before or after this one, in place of this one.
  void _go(PageRouteInfo route) {
    _keeper.keepWhatIsWaiting();
    context.router.replace(route);
  }

  String get _title {
    if (!_isPaper) return _reader.score?.title ?? 'Score';
    final paperName = (_collection?.entry?.description ?? '').trim();
    return paperName.isEmpty ? 'Played from paper' : paperName;
  }

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: Listenable.merge([_user, _reader, _collections]),
      builder: (context, _) {
        final mayView = _user.value?.isScoreViewer == true;
        return Scaffold(
          appBar: widget.performing && mayView
              ? _standAppBar(_wayThrough())
              : AppBar(title: Text(_title)),
          body: !mayView ? const ScoresAreForViewers() : _body(),
        );
      },
    );
  }

  AppBar _standAppBar(WayThrough? way) {
    return AppBar(
      toolbarHeight: way == null ? 48 : 56,
      titleSpacing: 0,
      // Back stays where back is, and the size and the key on the other side.
      centerTitle: way != null,
      title: way == null
          ? Text(_title, overflow: TextOverflow.ellipsis)
          : StandTitle(title: _title, way: way, onGo: _go),
      actions: [
        StandActions(
          reader: _reader,
          keptAsYourReading: _collection != null,
          onTouched: _keeper.keepReading,
        ),
      ],
    );
  }

  Widget _body() {
    final sheet = ScoreDetailSheet(
      reader: _reader,
      isPaper: _isPaper,
      paperNote: _collection == null
          ? 'This song is no longer in there.'
          : 'This one has not been scanned yet.',
      onTouched: _keeper.keepReading,
    );
    if (widget.performing) return sheet;
    return ScoreDetailsBody(
      about: ScoreAbout(
        reader: _reader,
        onPerform: _perform,
        mayUpload: _user.value?.isScoreEditor == true && !_isPaper,
        keptAsYourReading: _collection != null,
        onTouched: _keeper.keepReading,
      ),
      sheet: sheet,
    );
  }
}

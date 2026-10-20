import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/user_info.dart';
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
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/widgets/set_score_detail/paper_entry_body.dart';
import 'package:score/features/sets/widgets/set_score_detail/set_context.dart';
import 'package:score/features/sets/widgets/set_score_detail/set_entry_reading.dart';
import 'package:score/features/sets/widgets/set_score_detail/set_way_through.dart';
import 'package:score/features/sets/widgets/set_score_detail/stand_title.dart';
import 'package:score/features/sets/widgets/set_score_detail/way_bar.dart';
import 'package:score/features/sets/widgets/set_score_detail/way_through.dart';

class const SetScoreDetailPage({
  super.key,
  required final ScoreSet? set,
  required final String entryId,
  final bool isPerforming = false,
}) extends StatefulWidget {
  @override
  State<SetScoreDetailPage> createState() => _SetScoreDetailPageState();
}

class _SetScoreDetailPageState extends State<SetScoreDetailPage> {
  final _user = GetIt.I<AuthNotifier>();
  final _sets = GetIt.I<SetsNotifier>();
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

  late SetContext? _set = switch (widget.set) {
    final set? => switch (set.entries.indexWhere(
      (entry) => entry.id == widget.entryId,
    )) {
      < 0 => null,
      final index => SetContext(set: set, index: index),
    },
    null => null,
  };
  late final String? _scoreId = _set?.entry.scoreId;

  bool get _isPaper => _scoreId == null;

  Score? get _score => switch (_scoreId) {
    final scoreId? => _scores.getScore(scoreId),
    null => null,
  };

  SetEntryReading? get _reading => switch (_set) {
    final set? => SetEntryReading(entry: set.entry),
    null => null,
  };

  @override
  void initState() {
    super.initState();
    _reader.open();
    _keeper.start();
    _sets.addListener(_takeSetChanges);
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
    _sets.removeListener(_takeSetChanges);
    _reader.dispose();
    super.dispose();
  }

  void _takeSetChanges() {
    final context = _set;
    if (!mounted || context == null) return;
    final now = _sets.getSet(context.set.id);
    if (identical(now, context.set)) return;
    final index =
        now?.entries.indexWhere((entry) => entry.id == context.entry.id) ?? -1;
    // Taken out of the set, or the set deleted, while it is on the stand: the
    // score is still worth reading, but there is no running order around it
    // any more to show a place in, or to keep a reading against.
    if (now == null || index < 0) {
      _letGoOfTheEntry();
      return;
    }
    final entry = now.entries[index];
    // An entry written to play a different score while this one is open is
    // not this score's any more, and neither are its key and its parts: the
    // entry's page puts that score up in this one's place.
    if (entry.scoreId != _scoreId) {
      _letGoOfTheEntry();
      return;
    }
    setState(() => _set = SetContext(set: now, index: index));
    if (!_keeper.isPending) {
      _reader.view?.apply(SetEntryReading(entry: entry).onScreen);
    }
  }

  void _letGoOfTheEntry() {
    _keeper.cancel();
    setState(() => _set = null);
    _reader.view?.apply(const ScoreViewSettings.defaultView());
  }

  Future<bool> _saveReading(ScoreViewSettings onScreen) async {
    final context = _set;
    if (context == null) return true;
    final reading = SetEntryReading(entry: context.entry).toSave(onScreen);

    final saved = (await GetIt.I<SaveSetEntryView>()(
      SaveSetEntryViewParams(
        setId: context.set.id,
        entryId: context.entry.id,
        transposition: reading.transposition,
        hiddenParts: reading.hiddenParts,
        zoom: reading.zoom,
      ),
    )).orThrow();
    // Where the entry comes in the set is read again rather than kept: a sync
    // can have reordered the gig while this was being written, and taking the
    // place it used to be at would put somebody else's song on the screen.
    final moved = saved.entries.indexWhere(
      (entry) => entry.id == context.entry.id,
    );
    if (!mounted) return true;
    // Nor is the entry taken back once it has been let go of: a sync that
    // wrote it to play another score while this was on its way has already
    // said this page is not that entry's any more.
    if (_set == null ||
        (moved >= 0 && saved.entries[moved].scoreId != _scoreId)) {
      return false;
    }
    setState(() {
      _set = moved < 0 ? null : SetContext(set: saved, index: moved);
    });
    return true;
  }

  void _say(String message, {bool briefly = false}) {
    if (!mounted) return;
    say(context, message, briefly: briefly);
  }

  /// Opens the one before or after this one, in place of this one.
  void _go(PageRouteInfo route) {
    _keeper.keepWhatIsWaiting();
    context.router.replace(route);
  }

  void _perform() => setState(() => _performing = true);

  void _stopPerforming(bool didPop, Object? _) {
    if (!didPop) setState(() => _performing = false);
  }

  String get _title {
    if (!_isPaper) return _score?.title ?? 'Score';
    final paperName = (_set?.entry.description ?? '').trim();
    return paperName.isEmpty ? 'Played from paper' : paperName;
  }

  WayThrough? _wayThrough(bool performing) => switch (_set) {
    final set? => setWayThrough(context: set, performing: performing),
    null => null,
  };

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
                ? _standAppBar(_wayThrough(true))
                : AppBar(title: Text(_title)),
            body: !mayView
                ? const ScoresAreForViewers()
                : performing
                ? ImmersiveStand(child: _sheet())
                : _details(user),
          ),
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
          controller: _reader.view,
          keptAsYourReading: _set != null,
        ),
      ],
    );
  }

  Widget _paper({VoidCallback? onPerform}) {
    if (_reader.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return PaperEntryBody(
      note: _set == null
          ? 'This song is no longer in there.'
          : 'This one is played from paper.',
      onPerform: onPerform,
    );
  }

  Widget _sheet() {
    return _isPaper ? _paper() : ScoreDetailSheet(reader: _reader);
  }

  Widget _details(UserInfo user) {
    final way = _wayThrough(false);
    return Column(
      children: [
        if (way != null) WayBar(way: way, go: _go),
        Expanded(
          child: _isPaper
              ? _paper(onPerform: _perform)
              : ScoreDetailsBody(
                  reader: _reader,
                  onPerform: _perform,
                  score: _score,
                  user: user,
                  keptAsYourReading: _set != null,
                ),
        ),
      ],
    );
  }
}

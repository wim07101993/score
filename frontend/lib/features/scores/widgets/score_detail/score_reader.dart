import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_detail/models/entry_reading.dart';
import 'package:score/features/scores/widgets/score_detail/models/score_reading_handover.dart';

class ScoreReader({
  required final String? scoreId,
  final bool performing = false,
  final ScoreReadingHandover? handover,
  final EntryReading? Function()? reading,
}) extends ChangeNotifier {
  static const _writtenSpace = 7.5;
  static const _minSpace = _writtenSpace * ScoreViewSettings.minZoom;
  static const _maxSpace = _writtenSpace * ScoreViewSettings.maxZoom;

  static int _stands = 0;

  final _auth = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  List<ScorePartRef> _parts = const [];
  String? _musicXml;
  ScoreView? _view;
  bool _loading = true;
  Object? _failure;
  double _space = _writtenSpace;
  double _pinched = 1;
  DateTime? _shownFetchedAt;
  bool _disposed = false;

  List<ScorePartRef> get parts => _parts;
  String? get musicXml => _musicXml;
  ScoreView? get view => _view;
  bool get loading => _loading;
  Object? get failure => _failure;
  double get space => _space;
  bool get isShowing => !_loading && _failure == null;

  Score? get score => switch (scoreId) {
    final scoreId? => _scores.getScore(scoreId),
    null => null,
  };

  double get zoom => (_space * _pinched / _writtenSpace).clamp(
    ScoreViewSettings.minZoom,
    ScoreViewSettings.maxZoom,
  );

  void open() {
    _scores.addListener(_takeScoreChanges);
    // On the stand the score is all there is: the bars a device draws over the
    // top and the bottom of the screen are lines of music not shown. They come
    // back with a swipe from the edge, and for good once the stand is closed.
    if (performing && _stands++ == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (performing) {
      if (--_stands == 0) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      final view = _view;
      if (view != null) handover?.onReturn(view, zoom);
    }
    _scores.removeListener(_takeScoreChanges);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _takeScoreChanges() async {
    if (_disposed) return;
    final scoreId = this.scoreId;
    final score = this.score;
    _notify();
    final fetched = score?.lastFetchedFileAt;
    if (_musicXml == null || fetched == null || fetched == _shownFetchedAt) {
      return;
    }
    final newer = _shownFetchedAt != null && fetched.isAfter(_shownFetchedAt!);
    _shownFetchedAt = fetched;
    if (!newer) return;
    final musicXml = (await GetIt.I<GetMusicXml>()(scoreId!)).valueOrNull;
    if (_disposed || musicXml == null || musicXml == _musicXml) return;
    _show(musicXml, keepingTheView: true);
  }

  Future<void> load({Future<void> Function()? readEntry}) async {
    if (_auth.value?.isScoreViewer != true) {
      _loading = false;
      _notify();
      return;
    }
    final scoreId = this.scoreId;
    if (scoreId == null) {
      await readEntry?.call();
      _loading = false;
      _notify();
      return;
    }

    try {
      await readEntry?.call();
      final musicXml = (await GetIt.I<GetMusicXml>()(scoreId)).orThrow();
      if (_disposed) return;

      if (musicXml == null) {
        _loading = false;
        _failure =
            'This score is not on this device, and the server could'
            ' not be reached to fetch it.';
        _notify();
        return;
      }

      _shownFetchedAt = _scores.getScore(scoreId)?.lastFetchedFileAt;
      _show(musicXml);
    } catch (error) {
      _loading = false;
      _failure = error;
      _notify();
    }

    // Bookkeeping, done once the music is on the stand and apart from putting
    // it there: failing to say when the score was last opened — its details
    // could not be fetched, say — must not take the score off the screen.
    if (_musicXml != null) {
      unawaited(Future(() => GetIt.I<MarkScoreViewed>()(scoreId)));
    }
    unawaited(Future(() => GetIt.I<SyncScores>()()));
  }

  void _show(String musicXml, {bool keepingTheView = false}) {
    final parts = readParts(parseMusicXml(musicXml)).toList();
    var view = ScoreView.forParts(partIds: [for (final part in parts) part.id]);
    final before = _view;
    if (keepingTheView && before != null) {
      _musicXml = musicXml;
      _parts = parts;
      _view = view.withTransposition(before.transposition).withHiddenParts([
        for (final part in parts)
          if (before.isHidden(part.id)) part.id,
      ]);
      _notify();
      return;
    }

    final reading = this.reading?.call();
    if (reading != null) {
      // The score opens the way the band plays it and the way this player reads
      // it: the entry says the band is a tone down, the view says this player
      // reads that a fifth up, and what goes on screen is the two together —
      // at the size this player draws it, which is theirs alone.
      view = view
          .withTransposition(reading.readAt)
          .withHiddenParts(reading.hiddenParts);
      _space = _spaceFor(reading.zoom);
    }

    // Played from its details, it goes on being read the way it was being read
    // there — which is the entry's reading too when there is an entry, give or
    // take what was changed there in the moment before the stand was opened.
    final handover = this.handover;
    if (handover != null) {
      view = view
          .withTransposition(handover.view.transposition)
          .withHiddenParts([
            for (final part in parts)
              if (handover.view.isHidden(part.id)) part.id,
          ]);
      _space = _spaceFor(handover.zoom);
    }

    _musicXml = musicXml;
    _parts = parts;
    _view = view;
    _pinched = 1;
    _loading = false;
    _failure = null;
    _notify();
  }

  Future<void> upload(String musicXml) async {
    (await GetIt.I<UploadScore>()((scoreId!, musicXml))).orThrow();
    if (_disposed) return;
    _show(musicXml);
    await GetIt.I<SyncScores>()();
  }

  double _spaceFor(double zoom) =>
      (_writtenSpace * zoom).clamp(_minSpace, _maxSpace);

  bool drawnAt(double zoom) =>
      (_spaceFor(zoom) - _space * _pinched).abs() < 0.01;

  void _drawAt(double zoom) => _space = _spaceFor(zoom) / _pinched;

  void changeView(ScoreView Function(ScoreView) change) {
    final view = _view;
    if (view == null) return;
    _view = change(view);
    _notify();
  }

  void zoomBy(double step) {
    _space = (_space + step).clamp(_minSpace, _maxSpace);
    _notify();
  }

  void pinch(double pinched) {
    _pinched = pinched;
    _notify();
  }

  void reset() {
    final view = _view;
    if (view == null) return;
    _view = view.reset();
    _drawAt(1);
    _notify();
  }

  void takeReading({
    required EntryReading was,
    required EntryReading now,
    required bool keepTouched,
  }) {
    final view = _view;
    if (view == null || was == now) return;

    var next = view;
    if (!keepTouched || view.transposition == was.readAt) {
      next = next.withTransposition(now.readAt);
    }
    final hidden = view.hiddenPartIds;
    if (!keepTouched ||
        (hidden.length == was.hiddenParts.length &&
            was.hiddenParts.every(view.isHidden))) {
      next = next.withHiddenParts(now.hiddenParts);
    }
    _view = next;

    // The size is what the buttons set times what a pinch has added, and the
    // pinch is the sheet's to hold: it is the buttons' share that is moved, so
    // that the two together come out at the size the entry says.
    if (!keepTouched || drawnAt(was.zoom)) {
      _drawAt(now.zoom);
    }
    _notify();
  }

  ScoreReadingHandover? handOver() {
    final view = _view;
    if (view == null) return null;
    return ScoreReadingHandover(
      view: view,
      zoom: zoom,
      onReturn: takeBackFromTheStand,
    );
  }

  /// Takes on how the score was being read when the stand was closed. Not kept
  /// again: the stand kept it already, against whatever it is played from.
  ///
  /// The stand calls this while it is being taken down, which is no moment to
  /// rebuild anything in; so it waits for that to be over.
  void takeBackFromTheStand(ScoreView view, double zoom) {
    scheduleMicrotask(() {
      final now = _view;
      if (_disposed || now == null) return;
      _view = now.withTransposition(view.transposition).withHiddenParts([
        for (final part in _parts)
          if (view.isHidden(part.id)) part.id,
      ]);
      _drawAt(zoom);
      _notify();
    });
  }
}

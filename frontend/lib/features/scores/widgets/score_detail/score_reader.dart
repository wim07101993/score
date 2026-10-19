import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';

class ScoreReader({
  required final String? scoreId,
  final bool performing = false,
  final ScoreViewSettings? Function()? settings,
}) extends ChangeNotifier {
  final _auth = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  late final isPerforming = ValueNotifier(performing);

  ScoreViewController? _view;
  bool _loading = true;
  Object? _failure;
  String? _musicXml;
  DateTime? _shownFetchedAt;
  bool _disposed = false;

  ScoreViewController? get view => _view;
  String? get musicXml => _musicXml;
  bool get loading => _loading;
  Object? get failure => _failure;
  bool get isShowing => !_loading && _failure == null;

  void open() {
    _scores.addListener(_takeScoreChanges);
  }

  @override
  void dispose() {
    _disposed = true;
    _scores.removeListener(_takeScoreChanges);
    _view?.dispose();
    isPerforming.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _takeScoreChanges() async {
    final scoreId = this.scoreId;
    if (_disposed || scoreId == null) return;
    final fetched = _scores.getScore(scoreId)?.lastFetchedFileAt;
    if (_musicXml == null || fetched == null || fetched == _shownFetchedAt) {
      return;
    }
    final newer = _shownFetchedAt != null && fetched.isAfter(_shownFetchedAt!);
    _shownFetchedAt = fetched;
    if (newer) {
      await reload();
    }
  }

  Future<void> reload() async {
    final scoreId = this.scoreId;
    if (scoreId == null) return;
    final musicXml = (await GetIt.I<GetMusicXml>()(scoreId)).valueOrNull;
    if (_disposed || musicXml == null || musicXml == _musicXml) return;
    _show(musicXml);
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
    if (_view != null) {
      unawaited(Future(() => GetIt.I<MarkScoreViewed>()(scoreId)));
    }
    unawaited(Future(() => GetIt.I<SyncScores>()()));
  }

  void _show(String musicXml) {
    _musicXml = musicXml;
    _loading = false;
    try {
      final score = parseMusicXml(musicXml);
      final view = _view;
      if (view == null) {
        _view = ScoreViewController.forScore(
          score,
          settings: settings?.call() ?? const ScoreViewSettings.defaultView(),
        );
      } else {
        view.replaceScore(score);
      }
      _failure = null;
    } catch (error) {
      _failure = 'This score could not be read: $error';
    }
    _notify();
  }
}

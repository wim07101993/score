import 'dart:async';

import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/widgets/score_detail/models/entry_reading.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';

class ReadingKeeper({
  required final ScoreReader reader,
  required final EntryReading? Function() reading,
  required final Future<bool> Function(ScoreViewSettings reading) save,
  required final void Function() onLetGo,
  required final void Function(String message, {bool briefly}) say,
}) {
  Timer? _keeping;
  int _saving = 0;
  ScoreController? _watching;

  bool get isPending => _keeping != null || _saving > 0;

  void start() {
    reader.addListener(_watch);
    _watch();
  }

  void dispose() {
    keepWhatIsWaiting();
    reader.removeListener(_watch);
    _watching?.removeListener(_touched);
    _watching = null;
  }

  void _watch() {
    final controller = reader.view?.scoreController;
    if (identical(controller, _watching)) return;
    _watching?.removeListener(_touched);
    _watching = controller?..addListener(_touched);
  }

  void _touched() {
    if (_viewMatchesEntry) {
      cancel();
      return;
    }
    _keeping?.cancel();
    _keeping = Timer(const Duration(milliseconds: 400), keepWhatIsWaiting);
  }

  void cancel() {
    _keeping?.cancel();
    _keeping = null;
  }

  void keepWhatIsWaiting() {
    final waiting = _keeping;
    _keeping = null;
    if (waiting == null) return;
    waiting.cancel();
    if (_viewMatchesEntry) return;
    unawaited(_save());
  }

  /// Whether the way the score is on screen is the way the set or the
  /// collection says it is played and this player reads it — the size it is
  /// drawn at included. While it is, there is nothing to save.
  bool get _viewMatchesEntry {
    final reading = this.reading();
    final view = reader.view;
    if (reading == null || view == null) return true;
    return reading.isOnScreen(
      view.settings,
      partIds: view.parts.map((part) => part.id).toList(growable: false),
    );
  }

  /// Writes the way this player is looking at the score into the set or the
  /// collection, so that it opens that way the next time they play it.
  ///
  /// It is their own reading of it and nobody else's: the saxophone player
  /// saving their key changes nothing for the pianist. Neither the score nor
  /// the set is touched — what the band does is the owner's to say, and what is
  /// stored here is only how far this player reads it from there, which is what
  /// is on screen less the key the band plays it in. How big it is drawn goes
  /// with it, since that is theirs too.
  Future<void> _save() async {
    final reading = this.reading();
    final view = reader.view;
    if (reading == null || view == null) return;

    _saving++;
    try {
      final stillThisEntry = await save(reading.toSave(view.settings));
      if (!stillThisEntry) {
        onLetGo();
        return;
      }
      say('Saved as how you read it.', briefly: true);
    } catch (error) {
      say('How you read this could not be saved: $error');
    } finally {
      _saving--;
    }
  }
}

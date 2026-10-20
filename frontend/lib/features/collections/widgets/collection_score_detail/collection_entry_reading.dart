import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/models/score_view_settings.dart';

/// What an entry of a collection says about how its score is read: the key it is
/// on screen in, the parts that are not, and how big it is drawn.
class const CollectionEntryReading({
  required final CollectionEntry entry,
}) {
  ScoreViewSettings get onScreen => ScoreViewSettings(
    transposition: entry.combinedTransposition,
    hiddenParts: entry.view.hiddenParts,
    zoom: entry.view.zoom,
  );

  ScoreViewSettings toSave(ScoreViewSettings screen) => ScoreViewSettings(
    transposition: _offset(screen.transposition),
    hiddenParts: screen.hiddenParts,
    zoom: screen.zoom,
  );

  bool isOnScreen(ScoreViewSettings screen, {required List<String> partIds}) {
    final saved = entry.view;
    final kept = toSave(screen);
    final hiddenBefore = saved.hiddenParts.where(partIds.contains).toSet();
    final hiddenNow = kept.hiddenParts.toSet();
    return kept.transposition == saved.transposition &&
        hiddenBefore.length == hiddenNow.length &&
        hiddenBefore.containsAll(hiddenNow) &&
        (kept.zoom - saved.zoom).abs() < 0.01;
  }

  /// How far from the key the band plays it in a player reads a score, as
  /// saving what is on screen would store it.
  ///
  /// What is on screen is the band's key and the player's own offset added and
  /// then held to an octave either way, so it cannot always be taken apart
  /// again: the band up ten and the player up five shows as up twelve, and
  /// twelve less ten is not five. So while the screen is still where the saved
  /// reading put it, the offset that was saved is kept as it was, and hiding a
  /// part does not quietly turn up five into up two. Only a key the player
  /// actually moved to is worked out again, and held to the octave the API
  /// takes, so that a save button compared against this turns off once there
  /// is nothing different left to save.
  int _offset(int onScreen) {
    if (onScreen == entry.combinedTransposition) {
      return entry.view.transposition;
    }
    return (onScreen - entry.transposition).clamp(
      ScoreViewSettings.minTransposition,
      ScoreViewSettings.maxTransposition,
    );
  }
}

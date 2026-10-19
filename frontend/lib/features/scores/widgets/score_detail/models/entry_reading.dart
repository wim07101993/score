import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';

/// What an entry of a set or a collection says about how its score is read:
/// the key it is on screen in, the parts that are not, and how big it is
/// drawn.
class EntryReading._({
  required final int band,
  required final ScoreViewSettings saved,
  required final int readAt,
}) {
  EntryReading.ofSong({
    required SetEntry entry,
  }) : this._(
         band: entry.transposition,
         saved: entry.view,
         readAt: entry.combinedTransposition,
       );

  EntryReading.ofPiece({
    required CollectionEntry entry,
  }) : this._(
         band: entry.transposition,
         saved: entry.view,
         readAt: entry.combinedTransposition,
       );

  ScoreViewSettings get onScreen => ScoreViewSettings(
    transposition: readAt,
    hiddenParts: saved.hiddenParts,
    zoom: saved.zoom,
  );

  ScoreViewSettings toSave(ScoreViewSettings screen) => ScoreViewSettings(
    transposition: readingOffset(
      band: band,
      saved: saved.transposition,
      savedReadAt: readAt,
      onScreen: screen.transposition,
    ),
    hiddenParts: screen.hiddenParts,
    zoom: screen.zoom,
  );

  bool isOnScreen(ScoreViewSettings screen, {required List<String> partIds}) {
    final kept = toSave(screen);
    final hiddenBefore = saved.hiddenParts.where(partIds.contains).toSet();
    final hiddenNow = kept.hiddenParts.toSet();
    return kept.transposition == saved.transposition &&
        hiddenBefore.length == hiddenNow.length &&
        hiddenBefore.containsAll(hiddenNow) &&
        (kept.zoom - saved.zoom).abs() < 0.01;
  }
}

/// How far from the key the band plays it in ([band]) a player reads a score,
/// as saving what is on screen would store it.
///
/// What is on screen is the band's key and the player's own offset added and
/// then held to an octave either way, so it cannot always be taken apart
/// again: the band up ten and the player up five shows as up twelve, and
/// twelve less ten is not five. So while the screen is still where the saved
/// reading put it ([savedReadAt]), the offset that was [saved] is kept as it
/// was, and hiding a part does not quietly turn up five into up two. Only a
/// key the player actually moved to is worked out again, and held to the
/// octave the API takes, so that a save button compared against this turns
/// off once there is nothing different left to save.
int readingOffset({
  required int band,
  required int saved,
  required int savedReadAt,
  required int onScreen,
}) {
  if (onScreen == savedReadAt) return saved;
  return (onScreen - band).clamp(
    ScoreViewSettings.minTransposition,
    ScoreViewSettings.maxTransposition,
  );
}

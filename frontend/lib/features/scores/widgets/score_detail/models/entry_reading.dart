import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';

/// What an entry of a set or a collection says about how its score is read:
/// the key it is on screen in, the parts that are not, and how big it is
/// drawn.
///
/// Two of them are the same when the band's key and the player's own offset
/// are both the same, not only what they add up to: the one saved offset is
/// what [readingOffset] counts from, and a change to it with the sum held at
/// the octave is still a change to how the player's next save is worked out.
class EntryReading._({
  required final int band,
  required ScoreViewSettings view,
  required final int readAt,
}) {
  EntryReading.ofSong({
    required SetEntry entry,
  }) : this._(
         band: entry.transposition,
         view: entry.view,
         readAt: entry.combinedTransposition,
       );

  EntryReading.ofPiece({
    required CollectionEntry entry,
  }) : this._(
         band: entry.transposition,
         view: entry.view,
         readAt: entry.combinedTransposition,
       );

  this
    : saved = view.transposition,
      hiddenParts = view.hiddenParts,
      zoom = view.zoom;

  final int saved;
  final List<String> hiddenParts;
  final double zoom;

  @override
  bool operator ==(Object other) =>
      other is EntryReading &&
      other.band == band &&
      other.saved == saved &&
      other.readAt == readAt &&
      other.zoom == zoom &&
      other.hiddenParts.length == hiddenParts.length &&
      other.hiddenParts.every(hiddenParts.contains);

  @override
  int get hashCode => Object.hash(
    band,
    saved,
    readAt,
    zoom,
    Object.hashAllUnordered(hiddenParts),
  );
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

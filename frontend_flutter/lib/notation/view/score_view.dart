import 'package:flutter/foundation.dart';

/// How a score is being looked at: which of its parts are on screen and by how
/// much it is transposed.
///
/// A view is never stored and never travels back to the API. The document a
/// score is made of is what the editor uploaded and stays that way; hiding a
/// part or transposing is something that happens on the way to the screen and
/// nowhere else.
///
/// The state is immutable for the same reason: every change hands back a new
/// view, so the one a caller is holding can never turn into something else
/// underneath it, and putting a view back the way it was is a matter of keeping
/// the old one around.

/// The furthest a score can be transposed in either direction, in semitones.
const int minTransposition = -12;
const int maxTransposition = 12;

@immutable
class ScoreView {
  /// Prefer [ScoreView.forParts]; this takes its arguments already validated.
  ScoreView(List<String> partIds, List<String> hiddenPartIds, this.transposition)
      : partIds = List.unmodifiable(partIds),
        hiddenPartIds = List.unmodifiable(hiddenPartIds);

  /// The view a score opens in: every part on screen, written as it was
  /// written.
  factory ScoreView.forParts(List<String> partIds) =>
      ScoreView(partIds, const [], 0);

  /// Every part of the score, in the order the score lists them.
  final List<String> partIds;

  /// The parts that are not on screen.
  final List<String> hiddenPartIds;

  /// Semitones, negative for down.
  final int transposition;

  /// The parts on screen, in the order the score lists them.
  List<String> get visiblePartIds =>
      partIds.where((id) => !hiddenPartIds.contains(id)).toList();

  bool isHidden(String partId) => hiddenPartIds.contains(partId);

  /// Whether this is the score as it was written.
  bool get isPristine => transposition == 0 && hiddenPartIds.isEmpty;

  /// [semitones] beyond an octave either way is brought back to it.
  ScoreView withTransposition(int semitones) {
    final clamped = semitones.clamp(minTransposition, maxTransposition);
    if (clamped == transposition) {
      return this;
    }
    return ScoreView(partIds, hiddenPartIds, clamped);
  }

  /// Takes a part off the screen or puts it back.
  ///
  /// Hiding the last part that is left is refused rather than obeyed: a score
  /// with nothing on it is not a view of anything, and there would be no part
  /// left to click to get back. The view is returned unchanged, so a caller
  /// that draws its controls from the view shows the part as still visible.
  ScoreView withPartVisible(String partId, bool visible) {
    if (!partIds.contains(partId)) {
      return this;
    }
    if (visible == !isHidden(partId)) {
      return this;
    }

    if (visible) {
      return ScoreView(
        partIds,
        hiddenPartIds.where((id) => id != partId).toList(),
        transposition,
      );
    }

    if (visiblePartIds.length <= 1) {
      return this;
    }
    return ScoreView(partIds, [...hiddenPartIds, partId], transposition);
  }

  /// The same score with exactly these parts off the screen, whatever was off
  /// it before.
  ///
  /// This is how a score is opened the way a set says it is played: a set names
  /// the parts that are off screen all at once, and putting them off one by one
  /// would depend on the order they happen to be in.
  ///
  /// Parts the score does not have are ignored rather than refused: a set is
  /// written against the score as it was then, and a score that has been
  /// uploaded again since may no longer have the part that was hidden. Hiding
  /// every part there is, is refused the same way hiding the last one is.
  ScoreView withHiddenParts(List<String> partIds) {
    final hidden = this.partIds.where(partIds.contains).toList();
    if (hidden.length >= this.partIds.length) {
      return this;
    }
    if (hidden.length == hiddenPartIds.length &&
        hidden.every(hiddenPartIds.contains)) {
      return this;
    }
    return ScoreView(this.partIds, hidden, transposition);
  }

  /// The same score, looked at the way it was written.
  ScoreView reset() => ScoreView.forParts(partIds);

  @override
  bool operator ==(Object other) =>
      other is ScoreView &&
      other.transposition == transposition &&
      listEquals(other.partIds, partIds) &&
      listEquals(other.hiddenPartIds, hiddenPartIds);

  @override
  int get hashCode =>
      Object.hash(transposition, Object.hashAll(partIds), Object.hashAll(hiddenPartIds));

  @override
  String toString() =>
      'ScoreView(${partIds.length} parts, ${hiddenPartIds.length} hidden, $transposition semitones)';
}

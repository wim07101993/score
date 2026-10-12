import 'package:flutter/foundation.dart';
import 'package:score/features/scores/models/score_view_settings.dart';

@immutable
// Not const: the lists are copied into unmodifiable ones, which takes a call.
// ignore: prefer_const_constructors_in_immutables
class ScoreView({
  required List<String> partIds,
  required List<String> hiddenPartIds,

  /// Semitones, negative for down.
  required final int transposition,
}) {
  /// Prefer [ScoreView.forParts]; this takes its arguments already validated.
  this
    : partIds = List.unmodifiable(partIds),
      hiddenPartIds = List.unmodifiable(hiddenPartIds);

  /// The view a score opens in: every part on screen, written as it was
  /// written.
  factory ScoreView.forParts({
    required List<String> partIds,
  }) => ScoreView(partIds: partIds, hiddenPartIds: const [], transposition: 0);

  /// Every part of the score, in the order the score lists them.
  final List<String> partIds;

  /// The parts that are not on screen.
  final List<String> hiddenPartIds;

  /// The parts on screen, in the order the score lists them.
  List<String> get visiblePartIds =>
      partIds.where((id) => !hiddenPartIds.contains(id)).toList();

  bool isHidden(String partId) => hiddenPartIds.contains(partId);

  /// Whether this is the score as it was written.
  bool get isPristine => transposition == 0 && hiddenPartIds.isEmpty;

  /// [semitones] beyond an octave either way is brought back to it.
  ScoreView withTransposition(int semitones) {
    final clamped = semitones.clamp(
      ScoreViewSettings.minTransposition,
      ScoreViewSettings.maxTransposition,
    );
    if (clamped == transposition) {
      return this;
    }
    return ScoreView(
      partIds: partIds,
      hiddenPartIds: hiddenPartIds,
      transposition: clamped,
    );
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
        partIds: partIds,
        hiddenPartIds: hiddenPartIds.where((id) => id != partId).toList(),
        transposition: transposition,
      );
    }

    if (visiblePartIds.length <= 1) {
      return this;
    }
    return ScoreView(
      partIds: partIds,
      hiddenPartIds: [...hiddenPartIds, partId],
      transposition: transposition,
    );
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
    return ScoreView(
      partIds: this.partIds,
      hiddenPartIds: hidden,
      transposition: transposition,
    );
  }

  /// The same score, looked at the way it was written.
  ScoreView reset() => ScoreView.forParts(partIds: partIds);

  @override
  bool operator ==(Object other) =>
      other is ScoreView &&
      other.transposition == transposition &&
      listEquals(other.partIds, partIds) &&
      listEquals(other.hiddenPartIds, hiddenPartIds);

  @override
  int get hashCode => Object.hash(
    transposition,
    Object.hashAll(partIds),
    Object.hashAll(hiddenPartIds),
  );

  @override
  String toString() =>
      'ScoreView(${partIds.length} parts, ${hiddenPartIds.length} hidden, $transposition semitones)';
}

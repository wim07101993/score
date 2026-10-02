/// Narrowing the library down by what its scores say about themselves.
library;

import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models.dart';

/// A field the library can be narrowed by, and how to read it off a score.
///
/// Everything here is something a score says about itself in words that
/// repeat: two scores by the same composer say the same name, and a hundred
/// scores say a dozen names between them. That is what makes a list of them
/// worth ticking, and it is why the title is not among them — every score has
/// a different one, and a list of every title is the list of scores again.
class ScoreField {
  const ScoreField._(this.key, this.title, this.of);

  final String key;
  final String title;
  final List<String> Function(Score score) of;

  static final composers = ScoreField._(
    'composers',
    'Composers',
    (score) => score.creators.composers,
  );
  static final lyricists = ScoreField._(
    'lyricists',
    'Lyricists',
    (score) => score.creators.lyricists,
  );

  /// Read as their names rather than the sounds MusicXML writes, so that what
  /// is ticked is what the cards say.
  static final instruments = ScoreField._(
    'instruments',
    'Instruments',
    (score) => [for (final one in score.instruments) instrumentName(one)],
  );
  static final languages = ScoreField._(
    'languages',
    'Languages',
    (score) => score.languages,
  );
  static final tags = ScoreField._('tags', 'Tags', (score) => score.tags);

  static final all = [composers, lyricists, instruments, languages, tags];
}

/// One value of a field, and how many scores ticking it would leave.
typedef FieldValue = ({String value, int count});

/// What has been ticked, by field.
///
/// Ticking two composers asks for either of them, and ticking a composer and
/// an instrument asks for both. That is what ticking things means: two boxes
/// in one list widen it, and a box in a second list narrows what the first let
/// through.
class ScoreFilters {
  final Map<ScoreField, Set<String>> _ticked = {
    for (final field in ScoreField.all) field: {},
  };

  bool isTicked(ScoreField field, String value) =>
      _ticked[field]!.contains(value);

  void tick(ScoreField field, String value, {required bool wanted}) {
    if (wanted) {
      _ticked[field]!.add(value);
    } else {
      _ticked[field]!.remove(value);
    }
  }

  void clear() {
    for (final ticked in _ticked.values) {
      ticked.clear();
    }
  }

  /// How many boxes are ticked, across every field.
  int get count =>
      _ticked.values.fold(0, (count, ticked) => count + ticked.length);

  /// The scores that pass every field.
  ///
  /// [except] is a field to leave out, so that a field's own values can be
  /// counted against everything but itself: ticking a second composer has to
  /// be possible, and it would not be if the values were counted against a
  /// list the first composer had already narrowed.
  Iterable<Score> narrow(Iterable<Score> scores, {ScoreField? except}) =>
      scores.where((score) => ScoreField.all
          .every((field) => field == except || _passes(score, field)));

  /// Whether something listed beside the scores passes: a score when it is
  /// one, and for something with no score to read — a piece of a collection
  /// that was never scanned — only while nothing is ticked, as there is
  /// nothing it could be ticked by.
  bool passes(Score? score) =>
      score == null ? count == 0 : narrow([score]).isNotEmpty;

  bool _passes(Score score, ScoreField field) {
    final ticked = _ticked[field]!;
    return ticked.isEmpty || field.of(score).any(ticked.contains);
  }

  /// What [field] holds in [scores], most often first, and how many scores
  /// each would leave.
  ///
  /// A value that has been ticked is offered whatever it counts: something has
  /// to be there to untick.
  List<FieldValue> valuesOf(ScoreField field, Iterable<Score> scores) {
    final counts = <String, int>{};
    for (final score in narrow(scores, except: field)) {
      // A score that names the same composer twice is one score by them.
      for (final value in field.of(score).toSet()) {
        if (value.trim().isEmpty) continue;
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    for (final value in _ticked[field]!) {
      counts.putIfAbsent(value, () => 0);
    }

    return [
      for (final MapEntry(:key, :value) in counts.entries)
        (value: key, count: value),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.value.compareTo(b.value);
      });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models.dart';

const _bach = Score(
  id: 'bach',
  creators: Creators(composers: ['Bach']),
  languages: ['de'],
  tags: ['choir'],
);
const _faure = Score(
  id: 'faure',
  creators: Creators(composers: ['Fauré']),
  languages: ['fr'],
  tags: ['choir', 'solo'],
);
const _handel = Score(
  id: 'handel',
  creators: Creators(composers: ['Händel', 'Händel']),
  languages: ['de'],
);
const _scores = [_bach, _faure, _handel];

List<String> _ids(Iterable<Score> scores) =>
    [for (final score in scores) score.id];

void main() {
  test('nothing ticked lets everything through', () {
    expect(_ids(ScoreFilters().narrow(_scores)), ['bach', 'faure', 'handel']);
  });

  test('two values in one field widen, a second field narrows', () {
    final filters = ScoreFilters()
      ..tick(ScoreField.composers, 'Bach', wanted: true)
      ..tick(ScoreField.composers, 'Fauré', wanted: true);
    expect(_ids(filters.narrow(_scores)), ['bach', 'faure']);

    filters.tick(ScoreField.languages, 'fr', wanted: true);
    expect(_ids(filters.narrow(_scores)), ['faure']);
    expect(filters.count, 3);

    filters.clear();
    expect(filters.count, 0);
    expect(filters.narrow(_scores), hasLength(3));
  });

  test('values are counted most often first, a score once per value', () {
    expect(ScoreFilters().valuesOf(ScoreField.languages, _scores), [
      (value: 'de', count: 2),
      (value: 'fr', count: 1),
    ]);
    expect(
      ScoreFilters().valuesOf(ScoreField.composers, _scores),
      contains((value: 'Händel', count: 1)),
    );
  });

  test("a field's values are counted without its own ticks", () {
    final filters = ScoreFilters()
      ..tick(ScoreField.composers, 'Bach', wanted: true);

    // Fauré can still be ticked next to Bach…
    expect(
      filters.valuesOf(ScoreField.composers, _scores),
      contains((value: 'Fauré', count: 1)),
    );
    // …while the other fields count only what Bach leaves.
    expect(filters.valuesOf(ScoreField.tags, _scores), [
      (value: 'choir', count: 1),
    ]);
  });

  test('a ticked value that nothing has any more can still be unticked', () {
    final filters = ScoreFilters()
      ..tick(ScoreField.tags, 'gone', wanted: true);
    expect(
      filters.valuesOf(ScoreField.tags, _scores),
      contains((value: 'gone', count: 0)),
    );
  });
}

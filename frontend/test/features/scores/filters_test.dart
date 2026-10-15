import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models/creators.dart';
import 'package:score/features/scores/models/score.dart';

final _bach = Score(
  id: 'bach',
  creators: const Creators(composers: ['Bach']),
  languages: ['de'],
  tags: ['choir'],
  lastChangedAt: Score.defaultLastChangedAt,
);
final _faure = Score(
  id: 'faure',
  creators: const Creators(composers: ['Fauré']),
  languages: ['fr'],
  tags: ['choir', 'solo'],
  lastChangedAt: Score.defaultLastChangedAt,
);
final _handel = Score(
  id: 'handel',
  creators: const Creators(composers: ['Händel', 'Händel']),
  languages: ['de'],
  lastChangedAt: Score.defaultLastChangedAt,
);
final _scores = [_bach, _faure, _handel];

List<String> _ids(Iterable<Score> scores) => [
  for (final score in scores) score.id,
];

void main() {
  late ScoreFilter filter;
  late int notified;

  setUp(() {
    filter = ScoreFilter();
    notified = 0;
    filter.addListener(() => notified++);
  });

  tearDown(() => filter.dispose());

  test('nothing ticked lets everything through', () {
    expect(_ids(_scores.where(filter.call)), ['bach', 'faure', 'handel']);
  });

  test('two values in one field widen, a second field narrows', () {
    filter.composers.addAll(['Bach', 'Fauré']);
    expect(_ids(_scores.where(filter.call)), ['bach', 'faure']);

    filter.languages.add('fr');
    expect(_ids(_scores.where(filter.call)), ['faure']);
    expect(filter.count, 3);
  });

  test('every field narrows by its own values', () {
    filter.tags.add('solo');
    expect(_ids(_scores.where(filter.call)), ['faure']);

    filter.tags.clear();
    filter.lyricists.add('Nobody');
    expect(_scores.where(filter.call), isEmpty);
  });

  test('what is typed narrows as well', () {
    filter.query.text = 'faure';
    expect(_ids(_scores.where(filter.call)), ['faure']);
  });

  test('tells its listeners whenever anything in it changes', () {
    filter.composers.add('Bach');
    filter.query.text = 'b';
    expect(notified, 2);
  });

  test('clearing it tells its listeners once', () {
    filter.composers.add('Bach');
    filter.tags.add('choir');
    notified = 0;

    filter.clear();

    expect(filter.count, 0);
    expect(notified, 1);
    expect(_scores.where(filter.call), hasLength(3));
  });
}

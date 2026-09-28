import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/models.dart';

/// What a search looks through.
///
/// A score's facts come out of a MusicXML document, which names instruments by
/// a sound code. The list shows a player the name; a search has to answer to
/// the same word the list showed.

void main() {
  group('what a score can be found by', () {
    test('an instrument is found by the name the list shows for it', () {
      const score = Score(
        id: 'abc',
        instruments: ['keyboard.piano', 'wind.reed.clarinet'],
      );

      expect(score.searchText, contains('piano'));
      expect(score.searchText, contains('clarinet'));
    });

    test('the code it was written with still finds it', () {
      const score = Score(id: 'abc', instruments: ['keyboard.piano']);

      expect(score.searchText, contains('keyboard.piano'));
    });

    test('an instrument with no name of its own is kept as written', () {
      const score = Score(id: 'abc', instruments: ['metal.bells.agogo']);

      expect(score.searchText, contains('metal.bells.agogo'));
    });

    test('the title, the people and the tags are in there as well', () {
      const score = Score(
        id: 'abc',
        work: Work(title: 'Kind of Blue'),
        creators: Creators(composers: ['Miles Davis']),
        tags: ['jazz'],
      );

      expect(score.searchText, contains('kind of blue'));
      expect(score.searchText, contains('miles davis'));
      expect(score.searchText, contains('jazz'));
    });
  });
}

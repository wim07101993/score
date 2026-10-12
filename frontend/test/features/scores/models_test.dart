import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/models/creators.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/work.dart';

/// What a search looks through.
///
/// A score's facts come out of a MusicXML document, which names instruments by
/// a sound code. The list shows a player the name; a search has to answer to
/// the same word the list showed.

void main() {
  group('what a score can be found by', () {
    test('an instrument is found by the name the list shows for it', () {
      final score = Score(
        id: 'abc',
        instruments: ['keyboard.piano', 'wind.reed.clarinet'],
        lastChangedAt: Score.defaultLastChangedAt,
      );

      expect(score.searchText, contains('piano'));
      expect(score.searchText, contains('clarinet'));
    });

    test('the code it was written with still finds it', () {
      final score = Score(
        id: 'abc',
        instruments: ['keyboard.piano'],
        lastChangedAt: Score.defaultLastChangedAt,
      );

      expect(score.searchText, contains('keyboard.piano'));
    });

    test('an instrument with no name of its own is kept as written', () {
      final score = Score(
        id: 'abc',
        instruments: ['metal.bells.agogo'],
        lastChangedAt: Score.defaultLastChangedAt,
      );

      expect(score.searchText, contains('metal.bells.agogo'));
    });

    test('the title, the people and the tags are in there as well', () {
      final score = Score(
        id: 'abc',
        work: const Work(title: 'Kind of Blue'),
        creators: const Creators(composers: ['Miles Davis']),
        tags: ['jazz'],
        lastChangedAt: Score.defaultLastChangedAt,
      );

      expect(score.searchText, contains('kind of blue'));
      expect(score.searchText, contains('miles davis'));
      expect(score.searchText, contains('jazz'));
    });
  });

  group('looking for a score', () {
    final score = Score(
      id: 'abc',
      work: const Work(title: 'Après un rêve'),
      creators: const Creators(composers: ['Gabriel Fauré']),
      lastChangedAt: Score.defaultLastChangedAt,
    );

    test('finds it without the accents', () {
      expect(score.matches('apres'), isTrue);
      expect(score.matches('faure'), isTrue);
    });

    test('finds it with the accents too', () {
      expect(score.matches('APRÈS'), isTrue);
    });

    test('finds every word anywhere, in any order', () {
      expect(score.matches('faure reve'), isTrue);
      expect(score.matches('  rêve   gabriel '), isTrue);
    });

    test('does not find it when one of the words is not there', () {
      expect(score.matches('faure ravel'), isFalse);
    });

    test('an empty search finds everything', () {
      expect(score.matches(''), isTrue);
      expect(score.matches('   '), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/score_details.dart';

/// What a score is called and by whom, read on this device the way the server
/// reads it on upload.
void main() {
  final at = DateTime.utc(2026);

  test('the details are read the way the server reads them', () {
    final score = readScoreDetails(
      scoreId: 'abc',
      lastChangedAt: at,
      musicXml: '''
<score-partwise version="4.0">
  <work><work-number>Op. 7</work-number><work-title>Trois mélodies</work-title></work>
  <movement-number>1</movement-number>
  <movement-title>Après un rêve</movement-title>
  <identification>
    <creator type="composer">Gabriel Fauré</creator>
    <creator type="lyricist">Romain Bussine</creator>
    <creator type="composer">  </creator>
    <creator>Nobody knows what</creator>
  </identification>
  <defaults>
    <lyric-language xml:lang="it"/>
    <lyric-language xml:lang="fr"/>
  </defaults>
  <part-list>
    <score-part id="P1">
      <part-name>Voice</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Voice</instrument-name>
        <instrument-sound>voice.vocals</instrument-sound>
      </score-instrument>
    </score-part>
    <score-part id="P2">
      <part-name>Piano</part-name>
      <score-instrument id="P2-I1">
        <instrument-name>Piano</instrument-name>
        <instrument-sound>keyboard.piano</instrument-sound>
      </score-instrument>
      <score-instrument id="P2-I2"><instrument-name>?</instrument-name></score-instrument>
    </score-part>
  </part-list>
  <part id="P1"><measure number="1"/></part>
  <part id="P2"><measure number="1"/></part>
</score-partwise>
''',
    )!;

    expect(score.id, 'abc');
    expect(score.lastChangedAt, at);
    expect(score.work?.title, 'Trois mélodies');
    expect(score.work?.number, 'Op. 7');
    expect(score.movement?.title, 'Après un rêve');
    expect(score.movement?.number, '1');
    expect(score.creators.composers, ['Gabriel Fauré']);
    expect(score.creators.lyricists, ['Romain Bussine']);
    expect(score.languages, ['fr']);
    expect(score.instruments, ['voice.vocals', 'keyboard.piano']);
  });

  test('a document that is not MusicXML has no details', () {
    expect(
      readScoreDetails(scoreId: 'abc', lastChangedAt: at, musicXml: '<html/>'),
      isNull,
    );
    expect(
      readScoreDetails(scoreId: 'abc', lastChangedAt: at, musicXml: 'nope'),
      isNull,
    );
  });
}

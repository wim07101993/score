import test from 'node:test';
import assert from 'node:assert/strict';

import {intervalFor, transposeFifths, transposePitch} from './musicxml-view.js';

/** Every key a score is likely to be written in, and a few it is not. */
const KEYS = [-7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7];

/** Every distance the app lets a score be transposed by. */
const DISTANCES = [
  -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1,
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
];

/**
 * @param spelled {string} a note as it is written, such as "Eb4" or "F#3"
 * @return {import('./musicxml-view.js').Pitch}
 */
function pitch(spelled) {
  const [, step, accidental, octave] = spelled.match(/^([A-G])(b*|#*)(-?\d+)$/);
  return {
    step: step,
    alter: accidental.startsWith('b') ? -accidental.length : accidental.length,
    octave: Number(octave),
  };
}

/**
 * @param moved {import('./musicxml-view.js').Pitch}
 * @return {string}
 */
function spell(moved) {
  const accidental = moved.alter < 0
    ? 'b'.repeat(-moved.alter)
    : '#'.repeat(moved.alter);
  return `${moved.step}${accidental}${moved.octave}`;
}

/** What a written note sounds like, counted in semitones from C0. */
function sounds(spelled) {
  const note = pitch(spelled);
  return [0, 2, 4, 5, 7, 9, 11]['CDEFGAB'.indexOf(note.step)]
    + note.alter + 12 * note.octave;
}

/**
 * Transposes a note the way a score in C would be transposed.
 *
 * @param spelled {string}
 * @param semitones {number}
 * @param fifths {number}
 * @return {string}
 */
function transposed(spelled, semitones, fifths = 0) {
  return spell(transposePitch(pitch(spelled), intervalFor(semitones, fifths)));
}

// ---------------------------------------------------------------------------
// THE INTERVAL A SCORE MOVES BY
// ---------------------------------------------------------------------------

test('a distance in semitones is a distance in letters as well', () => {
  // A third is written as a third whether it is major or minor, which is why
  // three and four semitones both move two letters.
  const letters = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    .map((semitones) => intervalFor(semitones, 0).steps);

  assert.deepEqual(letters, [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7]);
});

test('going down moves as far as going up', () => {
  for (const semitones of DISTANCES.filter((distance) => distance !== 0)) {
    assert.equal(
      intervalFor(-semitones, 0).steps,
      -intervalFor(semitones, 0).steps,
      `${semitones} semitones`);
  }
});

test('an interval carries the distance it was asked for', () => {
  for (const fifths of KEYS) {
    for (const semitones of DISTANCES) {
      assert.equal(intervalFor(semitones, fifths).semitones, semitones);
    }
  }
});

test('an interval is never more than a semitone or so off the plain one', () => {
  // An interval is diminished, minor, major or augmented, and nothing further
  // out than that. A doubly augmented fourth is a sign the letter went the
  // wrong way, which is the failure this is here to catch.
  const plain = [0, 2, 4, 5, 7, 9, 11];

  for (const fifths of KEYS) {
    for (const semitones of DISTANCES) {
      const {steps} = intervalFor(semitones, fifths);
      const between = plain[((steps % 7) + 7) % 7] + 12 * Math.floor(steps / 7);
      assert.ok(
        Math.abs(semitones - between) <= 2,
        `${semitones} semitones in ${fifths} came out as ${steps} letters`);
    }
  }
});

// ---------------------------------------------------------------------------
// THE KEY IT IS WRITTEN IN
// ---------------------------------------------------------------------------

/**
 * @param fifths {number}
 * @param semitones {number}
 * @return {number}
 */
function movedKey(fifths, semitones) {
  return transposeFifths(fifths, intervalFor(semitones, fifths));
}

test('a key moves round the circle of fifths', () => {
  assert.equal(movedKey(0, 2), 2, 'D has two sharps');
  assert.equal(movedKey(0, 5), -1, 'F has one flat');
  assert.equal(movedKey(0, 7), 1, 'G has one sharp');
  assert.equal(movedKey(0, -2), -2, 'Bb has two flats');
  assert.equal(movedKey(0, -5), 1, 'G has one sharp');
});

test('a key is written whichever way round is easier to read', () => {
  // Up a semitone from C is Db with five flats, not C# with seven sharps.
  assert.equal(movedKey(0, 1), -5);
  // Down a semitone is B with five sharps, not Cb with seven flats.
  assert.equal(movedKey(0, -1), 5);
});

test('a key that is already a long way round comes back', () => {
  assert.equal(movedKey(7, 1), 2, 'C# up a semitone is D');
  assert.equal(movedKey(-7, -1), -2, 'Cb down a semitone is Bb');
});

test('a key transposed by an octave is the key it was', () => {
  for (const fifths of KEYS) {
    assert.equal(movedKey(fifths, 12), fifths);
    assert.equal(movedKey(fifths, -12), fifths);
  }
});

test('a key is never left somewhere a key signature cannot be written', () => {
  // Seven sharps or seven flats is every letter of the scale altered once, and
  // there is no such thing as an eighth. A transposition that lands past it has
  // to be spelled its other way instead.
  for (const fifths of KEYS) {
    for (const semitones of DISTANCES) {
      const moved = movedKey(fifths, semitones);
      assert.ok(
        Math.abs(moved) <= 7,
        `${fifths} moved by ${semitones} came out at ${moved}`);
    }
  }
});

test('a key too far round the circle is spelled the other way instead', () => {
  // Down a tritone from Bb, read plainly, is a diminished fifth to Fb major:
  // eight flats, which is not a key signature. It is E major with four sharps.
  assert.equal(movedKey(-2, -6), 4);
  // And up a tritone from C# is F## major before it is G major.
  assert.equal(movedKey(7, 6), 1);
});

// ---------------------------------------------------------------------------
// THE NOTES
// ---------------------------------------------------------------------------

test('a note keeps the interval it was written at', () => {
  // A minor third up is a third: two letters, however the accidental lands.
  assert.equal(transposed('C4', 3), 'Eb4');
  assert.equal(transposed('D4', 3), 'F4');
  assert.equal(transposed('E4', 3), 'G4');

  // A major second up is a second, never a third.
  assert.equal(transposed('C4', 2), 'D4');
  assert.equal(transposed('Bb3', 2), 'C4');
});

test('a sharp stays a sharp rather than turning into the letter above it', () => {
  // The one that gives a naive transposer away: D# up a minor third is F#,
  // because a third from D is an F. Reaching for whichever letter sits nearest
  // the new sound would give G, and a player reading a D#-F#-A# chord would be
  // handed one spelled D#-G-A#.
  assert.equal(transposed('D#4', 3), 'F#4');
  assert.equal(transposed('F#4', 3), 'A4');
  assert.equal(transposed('A#4', 3), 'C#5');
});

test('a note carries into the next octave when it runs off the end', () => {
  assert.equal(transposed('B4', 1), 'C5');
  assert.equal(transposed('A4', 3), 'C5');
  assert.equal(transposed('C4', -1), 'B3');
  assert.equal(transposed('C4', -12), 'C3');
  assert.equal(transposed('C0', -1), 'B-1');
});

test('a note transposed an octave is the note it was, an octave along', () => {
  for (const spelled of ['C4', 'Eb3', 'F#5', 'Bb2', 'A#4']) {
    assert.equal(transposed(spelled, 12), spelled.replace(/-?\d+$/, (o) => `${Number(o) + 1}`));
    assert.equal(transposed(spelled, -12), spelled.replace(/-?\d+$/, (o) => `${Number(o) - 1}`));
  }
});

test('a note transposed by nothing is the note it was', () => {
  for (const spelled of ['C4', 'Eb3', 'F#5', 'B4', 'Cb4']) {
    assert.equal(transposed(spelled, 0), spelled);
  }
});

test('a note keeps its distance from every other note', () => {
  // Whatever the spelling comes out as, the sound has to move by exactly what
  // was asked for. This is the half of it the spelling tests cannot see.
  for (const fifths of KEYS) {
    for (const spelled of ['C4', 'D#4', 'Eb3', 'F#5', 'B4', 'Cb4', 'A#2']) {
      for (const semitones of DISTANCES) {
        assert.equal(
          sounds(transposed(spelled, semitones, fifths)) - sounds(spelled),
          semitones,
          `${spelled} moved by ${semitones} in ${fifths}`);
      }
    }
  }
});

test('something that is not a note is handed straight back', () => {
  // The very object and not a copy of it. That identity is what tells a caller
  // writing into a document that there was nothing here it could read, and
  // without it the unreadable value would be written back into the score as
  // the word NaN.
  const interval = intervalFor(3, 0);

  for (const notANote of [
    {step: 'H', alter: 0, octave: 4},
    {step: '', alter: 0, octave: 4},
    {step: 'C', alter: 0, octave: NaN},
    {step: 'C', alter: NaN, octave: 4},
    {step: 'C', alter: 0, octave: Infinity},
  ]) {
    assert.equal(transposePitch(notANote, interval), notANote);
  }
});

test('a note this can read is never handed straight back', () => {
  // The other half of it: a caller telling the two apart by identity would
  // quietly stop transposing anything if a real note ever came back unchanged.
  for (const semitones of DISTANCES) {
    const note = {step: 'C', alter: 0, octave: 4};
    assert.notEqual(transposePitch(note, intervalFor(semitones, 0)), note);
  }
});

// ---------------------------------------------------------------------------
// THE TWO OF THEM TOGETHER
// ---------------------------------------------------------------------------

/**
 * How a letter is written in a given key: the sharps of a key signature are
 * added in the order F C G D A E B and the flats in the reverse of it, so how
 * many the signature has says which letters they land on.
 *
 * @param step {string}
 * @param fifths {number}
 * @return {number}
 */
function alterInKey(step, fifths) {
  const sharps = 'FCGDAEB'.indexOf(step);
  const flats = 'BEADGCF'.indexOf(step);
  if (fifths > 0) {
    return sharps < fifths ? 1 : 0;
  }
  return flats < -fifths ? -1 : 0;
}

test('the scale of a key transposes into the scale of the key it lands in', () => {
  // The strongest thing there is to say about a transposition: play the scale
  // of the key the score is in, transpose it, and what comes out has to be the
  // scale of the key the score is now in — the same seven notes the new key
  // signature describes, spelled the way it spells them. Nothing in a score can
  // be right if this is wrong, and it is checked in every key at every distance
  // the app allows.
  for (const fifths of KEYS) {
    for (const semitones of DISTANCES) {
      const interval = intervalFor(semitones, fifths);
      const key = transposeFifths(fifths, interval);

      for (const step of 'CDEFGAB') {
        const written = {step: step, alter: alterInKey(step, fifths), octave: 4};
        const moved = transposePitch(written, interval);

        assert.equal(
          moved.alter,
          alterInKey(moved.step, key),
          `${spell(written)} in ${fifths} moved by ${semitones}`
          + ` came out as ${spell(moved)}, which is not in ${key}`);
      }
    }
  }
});

test('the tritone takes the key and the notes the same way', () => {
  // There is no right answer to six semitones, only a convention, and the only
  // thing that would be wrong is the key going one way and the notes the other.
  assert.equal(transposed('C4', 6), 'F#4');
  assert.equal(movedKey(0, 6), 6, 'six sharps going up');

  assert.equal(transposed('C4', -6), 'Gb3');
  assert.equal(movedKey(0, -6), -6, 'six flats coming down');

  // And where the key had to be spelled the other way, the notes go with it: a
  // score in Bb goes down a tritone to E, so its Bb is an E and not an Fb.
  assert.equal(transposed('Bb4', -6, -2), 'E4');
});

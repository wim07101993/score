/**
 * Writing a score back out the way it is being looked at.
 *
 * A {@link import('./score-view.js').ScoreView} is something that happens on
 * the way to the screen: the document a score is made of is what the editor
 * uploaded and stays that way, and hiding a part or transposing never touches
 * it. That is the right thing right up until somebody wants what is on their
 * screen as a file — to print it, to hand it to a player who reads a different
 * key, to open it somewhere else. This is where the view stops being a way of
 * looking and becomes a document of its own.
 *
 * Nothing here writes to what it is given. A new document is parsed, changed
 * and handed back, so the score the app holds is the uploaded one either way.
 *
 * The music is all in the exported functions at the top, which are worth
 * reading on their own: they are what decides whether a transposed score is
 * spelled the way a player expects to read it, and they are the only part of
 * this file that can be tested without a browser.
 */

/** The letters of the scale, in the order MusicXML counts them. */
const STEPS = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

/** How far each of those letters stands from C, in semitones. */
const STEP_SEMITONES = [0, 2, 4, 5, 7, 9, 11];

/**
 * The same letters in the order the circle of fifths puts them, which is the
 * order a key signature adds accidentals in.
 */
const FIFTHS_STEPS = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];

/**
 * @typedef {Object} Pitch
 * @property {string} step one of A to G
 * @property {number} alter semitones, so 1 is a sharp and -1 a flat
 * @property {number} octave
 */

/**
 * How far a transposition moves, said the way a musician says it: so many
 * letters, and so many semitones. A minor third and a major third are both
 * three letters and differ only in the second number, which is exactly the
 * difference between an E flat and an E.
 *
 * @typedef {Object} Interval
 * @property {number} steps letters, negative for down
 * @property {number} semitones negative for down
 */

/**
 * How many letters a transposition moves by, for every distance up to an
 * octave. This is what keeps a transposed score readable: three semitones up is
 * a minor third, which moves two letters, so C becomes E flat and never D
 * sharp — a third is written as a third.
 */
const STEPS_PER_SEMITONE = [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7];

/**
 * The furthest round the circle of fifths a key signature can be written. Seven
 * sharps or seven flats is every letter of the scale altered once; past that
 * there is nothing left to alter.
 */
const MOST_ACCIDENTALS = 7;

/**
 * The interval a score is transposed by, which is a question the number of
 * semitones on its own cannot answer.
 *
 * Six semitones up from C is an F sharp or a G flat, and nothing in the note
 * itself decides which. Nearly always the plain reading of the distance is the
 * right one and the key follows it: up a semitone is a minor second, so a piece
 * in C goes to D flat.
 *
 * What that reading cannot do is stop at a key that can be written down. A
 * piece already a long way round the circle can be transposed clean off the end
 * of it — down a tritone from B flat is a diminished fifth to F flat major,
 * eight flats, a key signature that does not exist. The same sound spelled a
 * letter along is E major with four sharps, which is what a player would be
 * handed. So the plain reading is taken unless it lands somewhere unwritable,
 * and the way out is to move the letter rather than the sound.
 *
 * The decision is made once for the whole score, off the key it opens in: a
 * transposition is one interval, and every note and every key change in the
 * piece is moved by that same one.
 *
 * @param semitones {number}
 * @param fifths {number} the key the score opens in, as a count of sharps
 *   (positive) or flats (negative)
 * @return {Interval}
 */
export function intervalFor(semitones, fifths) {
  if (semitones === 0) {
    return {steps: 0, semitones: 0};
  }

  const octaves = Math.trunc(semitones / 12);
  const rest = semitones % 12;
  const plain = 7 * octaves + Math.sign(rest) * STEPS_PER_SEMITONE[Math.abs(rest)];

  let best = {steps: plain, semitones: semitones};
  let accidentals = Math.abs(transposeFifths(fifths, best));
  if (accidentals <= MOST_ACCIDENTALS) {
    return best;
  }

  for (const steps of [plain - 1, plain + 1]) {
    const candidate = {steps: steps, semitones: semitones};
    const written = Math.abs(transposeFifths(fifths, candidate));
    if (written < accidentals) {
      best = candidate;
      accidentals = written;
    }
  }
  return best;
}

/**
 * The same note, read at an interval from where it was written.
 *
 * The letter moves first and the accidental is worked out afterwards, rather
 * than reaching for whichever letter sits nearest the new sound. That is the
 * whole difference between a score a player can read and one they cannot:
 * transposing a D sharp up a minor third has to give an F sharp and not a G,
 * because the third it is part of is still a third.
 *
 * @param pitch {Pitch}
 * @param interval {Interval}
 * @return {Pitch} a new pitch, or the very object it was given back again when
 *   that is not a note this understands. Handing back the same object rather
 *   than a copy of it is how a caller tells the two apart, and a caller writing
 *   into a document needs to: what it was given is what was in the document,
 *   and writing that back out through here would put a misreading of it in the
 *   document's place.
 */
export function transposePitch(pitch, interval) {
  const step = STEPS.indexOf(pitch.step);
  const octave = pitch.octave;
  const alter = pitch.alter ?? 0;
  if (step < 0 || !Number.isFinite(octave) || !Number.isFinite(alter)) {
    return pitch;
  }

  // Where the letter lands, counted in letters from C0 so that running off the
  // end of an octave carries into the next one on its own.
  const letters = step + 7 * octave + interval.steps;
  const movedStep = ((letters % 7) + 7) % 7;
  const movedOctave = Math.floor(letters / 7);

  // What it has to sound like, less what that letter sounds like on its own.
  // Whatever is left over is the accidental that goes in front of it.
  const sound = STEP_SEMITONES[step] + alter + 12 * octave + interval.semitones;
  const movedAlter = sound - STEP_SEMITONES[movedStep] - 12 * movedOctave;

  return {step: STEPS[movedStep], alter: movedAlter, octave: movedOctave};
}

/**
 * The key signature a transposed score is written in, as a count of sharps
 * (positive) or flats (negative).
 *
 * This is the tonic moved by the same interval every note moves by, which is
 * what keeps the two of them agreeing: a score whose notes are spelled with
 * flats cannot be handed a key signature full of sharps.
 *
 * @param fifths {number}
 * @param interval {Interval}
 * @return {number}
 */
export function transposeFifths(fifths, interval) {
  const moved = transposePitch({..._tonicOf(fifths), octave: 4}, interval);
  return FIFTHS_STEPS.indexOf(moved.step) - 1 + 7 * moved.alter;
}

/**
 * The key whose signature has this many sharps or flats, as a note.
 *
 * @param fifths {number}
 * @return {{step: string, alter: number}}
 */
function _tonicOf(fifths) {
  const place = fifths + 1;
  return {
    step: FIFTHS_STEPS[((place % 7) + 7) % 7],
    alter: Math.floor(place / 7),
  };
}

/**
 * What to print in front of a note, for the accidentals a score can name. A
 * pitch that needs something stranger than a double sharp is left to whoever
 * reads the document to work out from the key.
 *
 * @type {Map<number, string>}
 */
const ACCIDENTALS = new Map([
  [-2, 'flat-flat'],
  [-1, 'flat'],
  [0, 'natural'],
  [1, 'sharp'],
  [2, 'double-sharp'],
]);

// ----------------------------------------------------------------------------
// THE DOCUMENT
// ----------------------------------------------------------------------------

/**
 * The score as the view has it: without the parts that are off screen, and in
 * the key it is being read in.
 *
 * A view that changes nothing hands back exactly what it was given, so
 * downloading a score nobody has touched is still the editor's own file, byte
 * for byte.
 *
 * @param musicXml {string}
 * @param view {import('./score-view.js').ScoreView|null}
 * @return {string}
 */
export function musicXmlForView(musicXml, view) {
  if (view == null || view.isPristine) {
    return musicXml;
  }

  const document = new DOMParser().parseFromString(musicXml, 'application/xml');
  // A parser that cannot read a document says so inside the document it hands
  // back rather than by throwing, and what it hands back is parseable enough to
  // go on working with unnoticed.
  const failure = document.getElementsByTagName('parsererror')[0];
  if (failure != null) {
    throw new Error(`the score cannot be read as xml: ${failure.textContent}`);
  }

  _removeHiddenParts(document, view);
  _transpose(document, view.transposition);

  // A serializer writes out the document and not the line in front of it, and
  // some of what reads MusicXML wants that line. It can be written rather than
  // carried over: what comes back from here is a string, and a string handed to
  // the browser to save is written as utf-8 whatever it used to be.
  return `<?xml version="1.0" encoding="UTF-8"?>\n`
    + new XMLSerializer().serializeToString(document);
}

/**
 * Takes the parts that are off screen out of the document altogether.
 *
 * A view names its parts the way the renderer named them, which is by the place
 * they come in the score rather than by anything written in the document — a
 * part with no usable id is still a part. So they are matched up by that place
 * here too, which is what the renderer itself does when it decides what to draw.
 *
 * @param document {Document}
 * @param view {import('./score-view.js').ScoreView}
 */
function _removeHiddenParts(document, view) {
  const declarations = [...document.getElementsByTagName('score-part')];

  view.partIds.forEach((partId, index) => {
    if (!view.isHidden(partId)) {
      return;
    }

    const declaration = declarations[index];
    if (declaration == null) {
      return;
    }
    const id = declaration.getAttribute('id');
    declaration.remove();

    // A part is declared in one place and played in another, and both of them
    // go.
    if (id == null) {
      return;
    }
    for (const part of [...document.getElementsByTagName('part')]) {
      if (part.getAttribute('id') === id) {
        part.remove();
      }
    }
  });
}

/**
 * @param document {Document}
 * @param semitones {number}
 */
function _transpose(document, semitones) {
  if (semitones === 0) {
    return;
  }

  const interval = intervalFor(semitones, _openingFifths(document));

  // The notes. One with no pitch is a rest, or something on a drum staff that
  // is written at a place rather than at a sound; neither of those transposes.
  for (const note of [...document.getElementsByTagName('note')]) {
    const pitch = _child(note, 'pitch');
    if (pitch == null) {
      continue;
    }
    const moved = _transposePitchLike(pitch, ['step', 'alter', 'octave'], interval);
    if (moved != null) {
      _rewriteAccidental(note, moved.alter);
    }
  }

  // The key signatures, of which a score can have any number: one to open with
  // and one at every change of key after that.
  for (const key of [...document.getElementsByTagName('key')]) {
    const fifths = _child(key, 'fifths');
    const written = _numberIn(fifths, NaN);
    if (Number.isFinite(written)) {
      fifths.textContent = `${transposeFifths(written, interval)}`;
    }
  }

  // The chord symbols, which are read off the page the same as the notes are.
  for (const root of [...document.getElementsByTagName('root')]) {
    _transposePitchLike(root, ['root-step', 'root-alter'], interval);
  }
  for (const bass of [...document.getElementsByTagName('bass')]) {
    _transposePitchLike(bass, ['bass-step', 'bass-alter'], interval);
  }

  // What the strings of a fretted instrument are tuned to, without which the
  // numbers on a tab staff would still be pointing at the old key.
  for (const tuning of [...document.getElementsByTagName('staff-tuning')]) {
    _transposePitchLike(tuning, ['tuning-step', 'tuning-alter', 'tuning-octave'], interval);
  }

  // What a transposing instrument sounds like against what it reads is a
  // property of the instrument and not of the music, so it is left alone: a
  // clarinet in B flat is still a clarinet in B flat in any key.
}

/**
 * The key the score opens in, which is the one the whole transposition is
 * worked out from. A score that never says gets read as C.
 *
 * @param document {Document}
 * @return {number}
 */
function _openingFifths(document) {
  for (const key of document.getElementsByTagName('key')) {
    const fifths = _numberIn(_child(key, 'fifths'), NaN);
    if (Number.isFinite(fifths)) {
      return fifths;
    }
  }
  return 0;
}

/**
 * Moves one of the several things MusicXML spells out as a letter, an
 * accidental and sometimes an octave: a note's pitch, the root or the bass of a
 * chord symbol, the tuning of a string.
 *
 * @param element {Element}
 * @param tags {string[]} what this one calls its step, its alter, and its
 *   octave if it has one
 * @param interval {Interval}
 * @return {Pitch|null} null if there was nothing here to move
 */
function _transposePitchLike(element, tags, interval) {
  const [stepTag, alterTag, octaveTag] = tags;

  const step = _child(element, stepTag);
  if (step == null) {
    return null;
  }
  const octave = octaveTag == null ? null : _child(element, octaveTag);
  const alter = _child(element, alterTag);

  const written = {
    step: `${step.textContent}`.trim(),
    // Something with no octave is a letter and nothing more: a chord symbol is
    // not written at a height. Any octave will do to move it, as long as the
    // one that comes back out is thrown away.
    octave: _numberIn(octave, 4),
    alter: _numberIn(alter, 0),
  };

  // A note this cannot read is left in the document exactly as it was found.
  // Transposing hands back what it was given when it does not understand it,
  // and putting that back through here would write the misreading down rather
  // than the note: an octave that was never a number would be saved as the
  // word NaN, and a score that was merely strange would come out broken.
  const moved = transposePitch(written, interval);
  if (moved === written) {
    return null;
  }

  step.textContent = moved.step;
  if (octave != null) {
    octave.textContent = `${moved.octave}`;
  }
  _writeAlter(element, alterTag, stepTag, moved.alter);
  return moved;
}

/**
 * Says how far a letter is bent, or stops saying it. Nothing at all is left out
 * rather than written as a zero, which is how a document that was never
 * transposed writes it.
 *
 * @param element {Element}
 * @param alterTag {string}
 * @param stepTag {string} what the alter has to come after, to leave the
 *   document in the order its schema puts it in
 * @param alter {number}
 */
function _writeAlter(element, alterTag, stepTag, alter) {
  const existing = _child(element, alterTag);
  if (alter === 0) {
    existing?.remove();
    return;
  }
  if (existing != null) {
    existing.textContent = `${alter}`;
    return;
  }

  const added = element.ownerDocument.createElement(alterTag);
  added.textContent = `${alter}`;
  const step = _child(element, stepTag);
  if (step == null) {
    element.appendChild(added);
  } else {
    step.after(added);
  }
}

/**
 * Puts the accidental in front of a note back in step with the note.
 *
 * Only a note that already had one gets one. What is printed in front of a note
 * and what the note sounds like are two different things in MusicXML, and a
 * score that leaves an accidental out is a score saying the key signature has
 * that one covered. Transposing changes none of that — every note keeps the
 * place it had in the scale — so an accidental that was written is still
 * written, and one that was not is still not.
 *
 * @param note {Element}
 * @param alter {number}
 */
function _rewriteAccidental(note, alter) {
  const accidental = _child(note, 'accidental');
  if (accidental == null) {
    return;
  }

  const named = ACCIDENTALS.get(alter);
  if (named == null) {
    // Something past a double sharp, or a fraction of a semitone. Saying
    // nothing leaves it to be worked out from the note and the key, which beats
    // printing the accidental the note used to have.
    accidental.remove();
    return;
  }
  accidental.textContent = named;
}

/**
 * A number written in the document, or NaN when what is written there is not
 * one.
 *
 * Nothing at all counts as not one. Reading an empty element as a zero is the
 * language's idea rather than the document's, and a zero is a real answer —
 * an octave, a key of no sharps and no flats — so it would be taken for
 * something the score said and written back as though it had.
 *
 * @param element {Element|null}
 * @param fallback {number} what an element that is not there at all means
 * @return {number}
 */
function _numberIn(element, fallback) {
  if (element == null) {
    return fallback;
  }
  const written = `${element.textContent}`.trim();
  return written === '' ? NaN : Number(written);
}

/**
 * @param parent {Element}
 * @param tagName {string}
 * @return {Element|null}
 */
function _child(parent, tagName) {
  for (const child of parent.children) {
    if (child.tagName === tagName) {
      return child;
    }
  }
  return null;
}

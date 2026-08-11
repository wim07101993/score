import 'package:xml/xml.dart';

import 'pitch.dart';
import 'score_view.dart';

/// Writing a score back out the way it is being looked at.
///
/// A [ScoreView] is something that happens on the way to the screen: the
/// document a score is made of is what the editor uploaded and stays that way,
/// and hiding a part or transposing never touches it. That is the right thing
/// right up until somebody wants what is on their screen as a file — to print
/// it, to hand it to a player who reads a different key, to open it somewhere
/// else.
///
/// It is also what the renderer draws from. Transposing on the way into the
/// engine rather than inside it means the score on screen and the score in the
/// downloaded file are the same document, worked out once: there is no second
/// implementation of what a transposed key signature is to disagree with the
/// first.
///
/// Nothing here writes to what it is given. A new document is parsed, changed
/// and handed back, so the score the app holds is the uploaded one either way.

/// The score as the view has it: without the parts that are off screen, and in
/// the key it is being read in.
///
/// A view that changes nothing hands back exactly what it was given, so
/// downloading a score nobody has touched is still the editor's own file, byte
/// for byte.
String musicXmlForView(String musicXml, ScoreView? view) {
  if (view == null || view.isPristine) {
    return musicXml;
  }
  return documentForView(musicXml, view).toXmlString();
}

/// The same thing as a parsed document, which is what the renderer wants: it
/// is about to walk it and would only parse the text straight back again.
XmlDocument documentForView(String musicXml, ScoreView? view) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(musicXml);
  } on XmlException catch (error) {
    throw FormatException('the score cannot be read as xml: $error');
  }

  // A serializer writes out the document and not the line in front of it, and
  // some of what reads MusicXML wants that line.
  if (document.declaration == null) {
    document.children.insert(
      0,
      XmlDeclaration([XmlAttribute(XmlName('version'), '1.0'), XmlAttribute(XmlName('encoding'), 'UTF-8')]),
    );
  }

  if (view == null || view.isPristine) {
    return document;
  }

  _removeHiddenParts(document, view);
  _transpose(document, view.transposition);
  return document;
}

/// Takes the parts that are off screen out of the document altogether.
///
/// A view names its parts the way the renderer named them, which is by the
/// place they come in the score rather than by anything written in the document
/// — a part with no usable id is still a part. So they are matched up by that
/// place here too, which is what the renderer itself does when it decides what
/// to draw.
void _removeHiddenParts(XmlDocument document, ScoreView view) {
  final declarations = document.findAllElements('score-part').toList();

  for (var index = 0; index < view.partIds.length; index++) {
    final partId = view.partIds[index];
    if (!view.isHidden(partId)) {
      continue;
    }
    if (index >= declarations.length) {
      continue;
    }

    final declaration = declarations[index];
    final id = declaration.getAttribute('id');
    declaration.remove();

    // A part is declared in one place and played in another, and both of them
    // go.
    if (id == null) {
      continue;
    }
    for (final part in document.findAllElements('part').toList()) {
      if (part.getAttribute('id') == id) {
        part.remove();
      }
    }
  }
}

void _transpose(XmlDocument document, int semitones) {
  if (semitones == 0) {
    return;
  }

  final interval = intervalFor(semitones, _openingFifths(document));

  // The notes. One with no pitch is a rest, or something on a drum staff that
  // is written at a place rather than at a sound; neither of those transposes.
  for (final note in document.findAllElements('note').toList()) {
    final pitch = _child(note, 'pitch');
    if (pitch == null) {
      continue;
    }
    final moved = _transposePitchLike(pitch, 'step', 'alter', 'octave', interval);
    if (moved != null) {
      _rewriteAccidental(note, moved.alter);
    }
  }

  // The key signatures, of which a score can have any number: one to open with
  // and one at every change of key after that.
  for (final key in document.findAllElements('key').toList()) {
    final fifths = _child(key, 'fifths');
    final written = _numberIn(fifths, double.nan);
    if (written.isFinite) {
      _setText(fifths!, formatNumber(transposeFifths(written.round(), interval)));
    }
  }

  // The chord symbols, which are read off the page the same as the notes are.
  for (final root in document.findAllElements('root').toList()) {
    _transposePitchLike(root, 'root-step', 'root-alter', null, interval);
  }
  for (final bass in document.findAllElements('bass').toList()) {
    _transposePitchLike(bass, 'bass-step', 'bass-alter', null, interval);
  }

  // What the strings of a fretted instrument are tuned to, without which the
  // numbers on a tab staff would still be pointing at the old key.
  for (final tuning in document.findAllElements('staff-tuning').toList()) {
    _transposePitchLike(
        tuning, 'tuning-step', 'tuning-alter', 'tuning-octave', interval);
  }

  // What a transposing instrument sounds like against what it reads is a
  // property of the instrument and not of the music, so it is left alone: a
  // clarinet in B flat is still a clarinet in B flat in any key.
}

/// The key the score opens in, which is the one the whole transposition is
/// worked out from. A score that never says gets read as C.
int _openingFifths(XmlDocument document) {
  for (final key in document.findAllElements('key')) {
    final fifths = _numberIn(_child(key, 'fifths'), double.nan);
    if (fifths.isFinite) {
      return fifths.round();
    }
  }
  return 0;
}

/// Moves one of the several things MusicXML spells out as a letter, an
/// accidental and sometimes an octave: a note's pitch, the root or the bass of
/// a chord symbol, the tuning of a string.
///
/// `null` when there was nothing here to move, or when what is here is not a
/// note this understands — in which case the document is left exactly as it was
/// found. Writing a misreading back would put an octave of NaN where a number
/// used to be, and a score that was merely strange would come out broken.
Pitch? _transposePitchLike(
  XmlElement element,
  String stepTag,
  String alterTag,
  String? octaveTag,
  Interval interval,
) {
  final step = _child(element, stepTag);
  if (step == null) {
    return null;
  }
  final octave = octaveTag == null ? null : _child(element, octaveTag);
  final alter = _child(element, alterTag);

  // Something with no octave is a letter and nothing more: a chord symbol is
  // not written at a height. Any octave will do to move it, as long as the one
  // that comes back out is thrown away.
  final writtenOctave = _numberIn(octave, 4);
  final writtenAlter = _numberIn(alter, 0);
  if (!writtenOctave.isFinite || !writtenAlter.isFinite) {
    return null;
  }

  final moved = transposePitch(
    Pitch(step.innerText.trim(), writtenAlter, writtenOctave.round()),
    interval,
  );
  if (moved == null) {
    return null;
  }

  _setText(step, moved.step);
  if (octave != null) {
    _setText(octave, formatNumber(moved.octave));
  }
  _writeAlter(element, alterTag, stepTag, moved.alter);
  return moved;
}

/// Says how far a letter is bent, or stops saying it. Nothing at all is left
/// out rather than written as a zero, which is how a document that was never
/// transposed writes it.
void _writeAlter(
    XmlElement element, String alterTag, String stepTag, double alter) {
  final existing = _child(element, alterTag);
  if (alter == 0) {
    existing?.remove();
    return;
  }
  if (existing != null) {
    _setText(existing, formatNumber(alter));
    return;
  }

  final added = XmlElement(XmlName(alterTag), [], [XmlText(formatNumber(alter))]);
  final step = _child(element, stepTag);
  if (step == null) {
    element.children.add(added);
    return;
  }
  // After the step, to leave the document in the order its schema puts it in.
  element.children.insert(element.children.indexOf(step) + 1, added);
}

/// Puts the accidental in front of a note back in step with the note.
///
/// Only a note that already had one gets one. What is printed in front of a
/// note and what the note sounds like are two different things in MusicXML, and
/// a score that leaves an accidental out is a score saying the key signature
/// has that one covered. Transposing changes none of that — every note keeps
/// the place it had in the scale — so an accidental that was written is still
/// written, and one that was not is still not.
void _rewriteAccidental(XmlElement note, double alter) {
  final accidental = _child(note, 'accidental');
  if (accidental == null) {
    return;
  }

  final named = accidentalNameFor(alter);
  if (named == null) {
    // Something past a double sharp, or a fraction of a semitone. Saying
    // nothing leaves it to be worked out from the note and the key, which beats
    // printing the accidental the note used to have.
    accidental.remove();
    return;
  }
  _setText(accidental, named);
}

/// A number written in the document, or NaN when what is written there is not
/// one.
///
/// Nothing at all counts as not one. Reading an empty element as a zero is the
/// language's idea rather than the document's, and a zero is a real answer — an
/// octave, a key of no sharps and no flats — so it would be taken for something
/// the score said and written back as though it had.
double _numberIn(XmlElement? element, double fallback) {
  if (element == null) {
    return fallback;
  }
  final written = element.innerText.trim();
  if (written.isEmpty) {
    return double.nan;
  }
  return double.tryParse(written) ?? double.nan;
}

XmlElement? _child(XmlElement parent, String tagName) {
  for (final child in parent.childElements) {
    if (child.name.local == tagName) {
      return child;
    }
  }
  return null;
}

/// Replaces what an element says, leaving whatever it is made of behind. An
/// element that is only text is the common case, and one that is not was not
/// something this understood anyway.
void _setText(XmlElement element, String text) {
  element.children
    ..clear()
    ..add(XmlText(text));
}

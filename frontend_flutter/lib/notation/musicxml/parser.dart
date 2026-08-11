import 'package:xml/xml.dart';

import '../view/pitch.dart';
import 'model.dart';

/// Reading a MusicXML document into something that can be drawn.
///
/// The reader is forgiving on purpose. A part with no id, a measure whose
/// durations do not add up, an element nobody has heard of: none of them stops
/// a score being read, because a player holding a slightly broken part still
/// wants to see it. What cannot be read is left out, and everything around it
/// is drawn.

class MusicXmlParseException implements Exception {
  MusicXmlParseException(this.message);

  final String message;

  @override
  String toString() => 'MusicXmlParseException: $message';
}

/// Reads a score out of the text of a document.
MusicXmlScore parseMusicXml(String source) => parseMusicXmlDocument(
      _parse(source),
    );

XmlDocument _parse(String source) {
  try {
    return XmlDocument.parse(source);
  } on XmlException catch (error) {
    throw MusicXmlParseException('the score cannot be read as xml: $error');
  }
}

/// Reads a score out of a document that has already been parsed, which is what
/// the viewer does: it has just transposed one.
MusicXmlScore parseMusicXmlDocument(XmlDocument document) {
  final root = document.rootElement;

  if (root.name.local == 'score-timewise') {
    throw MusicXmlParseException(
      'this score is written bar by bar rather than part by part'
      ' (score-timewise), which this cannot read yet',
    );
  }
  if (root.name.local != 'score-partwise') {
    throw MusicXmlParseException(
      'this is not a MusicXML score: the document is a <${root.name.local}>',
    );
  }

  final names = _partNames(root);

  return MusicXmlScore(
    workTitle: _text(_child(root, 'work'), 'work-title'),
    workNumber: _text(_child(root, 'work'), 'work-number'),
    movementTitle: _text(root, 'movement-title'),
    movementNumber: _text(root, 'movement-number'),
    composers: _creators(root, 'composer'),
    lyricists: _creators(root, 'lyricist'),
    parts: [
      for (final part in root.childElements.where((e) => e.name.local == 'part'))
        _readPart(part, names),
    ],
  );
}

/// What the part list calls each part, by the id it calls it by.
Map<String, _PartName> _partNames(XmlElement root) {
  final names = <String, _PartName>{};
  final list = _child(root, 'part-list');
  if (list == null) {
    return names;
  }
  for (final declaration in list.childElements) {
    if (declaration.name.local != 'score-part') {
      continue;
    }
    final id = declaration.getAttribute('id');
    if (id == null) {
      continue;
    }
    names[id] = _PartName(
      _text(declaration, 'part-name'),
      _text(declaration, 'part-abbreviation'),
    );
  }
  return names;
}

class _PartName {
  _PartName(this.name, this.abbreviation);

  final String? name;
  final String? abbreviation;
}

List<String> _creators(XmlElement root, String type) {
  final identification = _child(root, 'identification');
  if (identification == null) {
    return const [];
  }
  return [
    for (final creator in identification.childElements)
      if (creator.name.local == 'creator' &&
          creator.getAttribute('type') == type &&
          creator.innerText.trim().isNotEmpty)
        creator.innerText.trim(),
  ];
}

Part _readPart(XmlElement element, Map<String, _PartName> names) {
  final id = element.getAttribute('id') ?? '';
  final name = names[id];
  return Part(
    id: id,
    name: name?.name,
    abbreviation: name?.abbreviation,
    measures: [
      for (final measure in element.childElements)
        if (measure.name.local == 'measure') _readMeasure(measure),
    ],
  );
}

Measure _readMeasure(XmlElement element) {
  final items = <MeasureItem>[];

  for (final child in element.childElements) {
    switch (child.name.local) {
      case 'attributes':
        items.add(_readAttributes(child));
      case 'note':
        items.add(_readNote(child));
      case 'backup':
        items.add(Backup(_int(child, 'duration') ?? 0));
      case 'forward':
        items.add(Forward(_int(child, 'duration') ?? 0));
      case 'direction':
        final direction = _readDirection(child);
        if (direction != null) items.add(direction);
      case 'harmony':
        final harmony = _readHarmony(child);
        if (harmony != null) items.add(harmony);
      case 'barline':
        items.add(_readBarline(child));
      case 'print':
        items.add(Print(
          newSystem: child.getAttribute('new-system') == 'yes',
          newPage: child.getAttribute('new-page') == 'yes',
        ));
    }
  }

  return Measure(
    number: element.getAttribute('number') ?? '',
    implicit: element.getAttribute('implicit') == 'yes',
    items: items,
  );
}

Attributes _readAttributes(XmlElement element) {
  final keys = <KeySignature>[];
  final times = <TimeSignature>[];
  final clefs = <Clef>[];

  for (final child in element.childElements) {
    switch (child.name.local) {
      case 'key':
        final fifths = _int(child, 'fifths');
        if (fifths != null) {
          keys.add(KeySignature(
            fifths: fifths,
            staff: _intAttribute(child, 'number'),
            mode: _text(child, 'mode'),
          ));
        }
      case 'time':
        // A document can state more than one, for a bar in two time signatures
        // at once. The first is the one drawn.
        final beats = _int(child, 'beats');
        final beatType = _int(child, 'beat-type');
        if (beats != null && beatType != null) {
          times.add(TimeSignature(
            beats: beats,
            beatType: beatType,
            staff: _intAttribute(child, 'number'),
            symbol: child.getAttribute('symbol'),
          ));
        } else if (child.getAttribute('symbol') == 'common') {
          times.add(const TimeSignature(beats: 4, beatType: 4, symbol: 'common'));
        } else if (child.getAttribute('symbol') == 'cut') {
          times.add(const TimeSignature(beats: 2, beatType: 2, symbol: 'cut'));
        }
      case 'clef':
        final sign = _text(child, 'sign');
        if (sign != null) {
          clefs.add(Clef(
            sign: sign,
            line: _int(child, 'line'),
            octaveChange: _int(child, 'clef-octave-change') ?? 0,
            staff: _intAttribute(child, 'number') ?? 1,
          ));
        }
    }
  }

  final transpose = _child(element, 'transpose');

  return Attributes(
    divisions: _int(element, 'divisions'),
    keys: keys,
    times: times,
    staves: _int(element, 'staves'),
    clefs: clefs,
    transpose: transpose == null
        ? null
        : Transpose(
            diatonic: _int(transpose, 'diatonic') ?? 0,
            chromatic: _int(transpose, 'chromatic') ?? 0,
            octaveChange: _int(transpose, 'octave-change') ?? 0,
          ),
  );
}

Note _readNote(XmlElement element) {
  final pitchElement = _child(element, 'pitch');
  final restElement = _child(element, 'rest');
  final unpitchedElement = _child(element, 'unpitched');

  final beams = <int, String>{};
  for (final beam in element.childElements) {
    if (beam.name.local != 'beam') {
      continue;
    }
    beams[_intAttribute(beam, 'number') ?? 1] = beam.innerText.trim();
  }

  final timeModification = _child(element, 'time-modification');

  return Note(
    duration: _int(element, 'duration') ?? 0,
    pitch: pitchElement == null ? null : _readPitch(pitchElement),
    rest: restElement == null
        ? null
        : Rest(
            displayStep: _text(restElement, 'display-step'),
            displayOctave: _int(restElement, 'display-octave'),
            isMeasure: restElement.getAttribute('measure') == 'yes',
          ),
    unpitched: unpitchedElement == null
        ? null
        : Unpitched(
            displayStep: _text(unpitchedElement, 'display-step'),
            displayOctave: _int(unpitchedElement, 'display-octave'),
          ),
    isChord: _child(element, 'chord') != null,
    isGrace: _child(element, 'grace') != null,
    isCue: _child(element, 'cue') != null,
    voice: _int(element, 'voice') ?? 1,
    staff: _int(element, 'staff') ?? 1,
    type: _text(element, 'type'),
    dots: element.childElements.where((e) => e.name.local == 'dot').length,
    accidental: _text(element, 'accidental'),
    stem: _text(element, 'stem'),
    noteheadType: _text(element, 'notehead'),
    beams: beams,
    timeModification: timeModification == null
        ? null
        : TimeModification(
            actualNotes: _int(timeModification, 'actual-notes') ?? 1,
            normalNotes: _int(timeModification, 'normal-notes') ?? 1,
          ),
    notations: _readNotations(_child(element, 'notations')),
    lyrics: [
      for (final lyric in element.childElements)
        if (lyric.name.local == 'lyric') ..._readLyric(lyric),
    ],
  );
}

Pitch _readPitch(XmlElement element) => Pitch(
      _text(element, 'step') ?? 'C',
      _double(element, 'alter') ?? 0,
      _int(element, 'octave') ?? 4,
    );

Notations _readNotations(XmlElement? element) {
  if (element == null) {
    return const Notations();
  }

  var tieStarts = false;
  var tieStops = false;
  final slurs = <Slur>[];
  final articulations = <String>[];
  final ornaments = <String>[];
  var fermata = false;
  var arpeggiate = false;
  String? tuplet;

  for (final child in element.childElements) {
    switch (child.name.local) {
      case 'tied':
        final type = child.getAttribute('type');
        if (type == 'start') tieStarts = true;
        // A tie that both stops and starts is a note in the middle of a chain
        // of them, so these are not exclusive.
        if (type == 'stop') tieStops = true;
        if (type == 'continue') {
          tieStops = true;
          tieStarts = true;
        }
      case 'slur':
        final type = child.getAttribute('type');
        if (type != null) {
          slurs.add(Slur(
            number: _intAttribute(child, 'number') ?? 1,
            type: type,
            placement: child.getAttribute('placement'),
          ));
        }
      case 'tuplet':
        tuplet = child.getAttribute('type');
      case 'fermata':
        fermata = true;
      case 'arpeggiate':
        arpeggiate = true;
      case 'articulations':
        for (final articulation in child.childElements) {
          articulations.add(articulation.name.local);
        }
      case 'ornaments':
        for (final ornament in child.childElements) {
          ornaments.add(ornament.name.local);
        }
    }
  }

  return Notations(
    tieStarts: tieStarts,
    tieStops: tieStops,
    slurs: slurs,
    articulations: articulations,
    ornaments: ornaments,
    fermata: fermata,
    arpeggiate: arpeggiate,
    tuplet: tuplet,
  );
}

/// The words under one note. A lyric can carry more than one syllable in
/// documents that write elisions, so this hands back a list.
List<Lyric> _readLyric(XmlElement element) {
  final number = _intAttribute(element, 'number') ??
      int.tryParse(element.getAttribute('name') ?? '') ??
      1;

  final lyrics = <Lyric>[];
  String? syllabic;
  for (final child in element.childElements) {
    switch (child.name.local) {
      case 'syllabic':
        syllabic = child.innerText.trim();
      case 'text':
        lyrics.add(Lyric(
          text: child.innerText,
          number: number,
          syllabic: syllabic,
          extend: false,
        ));
        syllabic = null;
    }
  }

  if (lyrics.isEmpty && _child(element, 'extend') != null) {
    return [Lyric(text: '', number: number, extend: true)];
  }
  return lyrics;
}

Direction? _readDirection(XmlElement element) {
  String? words;
  String? dynamics;
  String? wedge;
  String? metronome;

  for (final type in element.childElements) {
    if (type.name.local != 'direction-type') {
      continue;
    }
    for (final child in type.childElements) {
      switch (child.name.local) {
        case 'words':
          words = ((words ?? '') + child.innerText).trim();
        case 'dynamics':
          // A dynamic is written as the letters it is made of: <p/><p/> is pp.
          dynamics = child.childElements.map((e) => e.name.local).join();
        case 'wedge':
          wedge = child.getAttribute('type');
        case 'metronome':
          final unit = _text(child, 'beat-unit');
          final perMinute = _text(child, 'per-minute');
          if (unit != null && perMinute != null) {
            metronome = '$unit = $perMinute';
          }
      }
    }
  }

  if (words == null && dynamics == null && wedge == null && metronome == null) {
    return null;
  }

  return Direction(
    words: words == null || words.isEmpty ? null : words,
    dynamics: dynamics == null || dynamics.isEmpty ? null : dynamics,
    wedge: wedge,
    metronome: metronome,
    placement: element.getAttribute('placement'),
    staff: _int(element, 'staff') ?? 1,
    offset: _int(element, 'offset') ?? 0,
  );
}

Harmony? _readHarmony(XmlElement element) {
  final root = _child(element, 'root');
  final step = root == null ? null : _text(root, 'root-step');
  if (step == null) {
    return null;
  }

  final bass = _child(element, 'bass');
  final kind = _child(element, 'kind');

  return Harmony(
    rootStep: step,
    rootAlter: root == null ? 0 : (_double(root, 'root-alter') ?? 0),
    kind: kind?.innerText.trim(),
    kindText: kind?.getAttribute('text'),
    bassStep: bass == null ? null : _text(bass, 'bass-step'),
    bassAlter: bass == null ? 0 : (_double(bass, 'bass-alter') ?? 0),
    offset: _int(element, 'offset') ?? 0,
  );
}

Barline _readBarline(XmlElement element) {
  final repeat = _child(element, 'repeat');
  final ending = _child(element, 'ending');

  return Barline(
    location: element.getAttribute('location') ?? 'right',
    barStyle: _text(element, 'bar-style'),
    repeatDirection: repeat?.getAttribute('direction'),
    endingNumber: ending?.getAttribute('number'),
    endingType: ending?.getAttribute('type'),
    fermata: _child(element, 'fermata') != null,
  );
}

// ---------------------------------------------------------------------------
// READING WHAT IS THERE
// ---------------------------------------------------------------------------

XmlElement? _child(XmlElement? parent, String name) {
  if (parent == null) {
    return null;
  }
  for (final child in parent.childElements) {
    if (child.name.local == name) {
      return child;
    }
  }
  return null;
}

String? _text(XmlElement? parent, String name) {
  final element = _child(parent, name);
  if (element == null) {
    return null;
  }
  final written = element.innerText.trim();
  return written.isEmpty ? null : written;
}

int? _int(XmlElement? parent, String name) {
  final written = _text(parent, name);
  if (written == null) {
    return null;
  }
  // Written as a decimal in documents that count in fractions of a division,
  // which is still a whole number of them as far as anything here is concerned.
  return int.tryParse(written) ?? double.tryParse(written)?.round();
}

double? _double(XmlElement? parent, String name) {
  final written = _text(parent, name);
  return written == null ? null : double.tryParse(written);
}

int? _intAttribute(XmlElement element, String name) {
  final written = element.getAttribute(name);
  return written == null ? null : int.tryParse(written.trim());
}

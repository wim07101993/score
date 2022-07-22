import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';
import 'package:score/shared/data/map_helpers.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/score.dart';

class ScoreFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String subtitle = 'subtitle';
  static const String dedication = 'dedication';
  static const String createdAt = 'createdAt';
  static const String modifiedAt = 'modifiedAt';
  static const String composers = 'composers';
  static const String arrangements = 'arrangements';
  static const String tags = 'tags';
}

class ArrangementFields {
  static const String name = 'name';
  static const String arrangers = 'arrangers';
  static const String parts = 'parts';
  static const String lyricists = 'lyricists';
  static const String description = 'description';
}

class ArrangementPartFields {
  static const String links = 'links';
  static const String description = 'description';
  static const String targetInstrument = 'targetInstrument';
}

class InstrumentNames {
  static const String guitar = 'guitar';
  static const String piano = 'piano';
  static const String flute = 'flute';
  static const String violin = 'violin';
  static const String cello = 'cello';
  static const String clarinet = 'clarinet';
  static const String trumpet = 'trumpet';
}

extension ScoresCollectionExtensions on FirebaseFirestore {
  CollectionReference<Score> get scoresCollection {
    return collection('scores').withConverter<Score>(
      fromFirestore: _docToScore,
      toFirestore: _scoreToDoc,
    );
  }

  Score _docToScore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final title = doc.maybeGet<String>(ScoreFields.title);
    final createdAt = doc.maybeGetDateTime(ScoreFields.createdAt);
    final modifiedAt = doc.maybeGetDateTime(ScoreFields.modifiedAt);
    final composers = doc
        .maybeGetList<String>(ScoreFields.composers)
        ?.toList(growable: false);
    final arrangements = doc
        .maybeGetListConverted<Arrangement>(
          ScoreFields.arrangements,
          _mapToArrangement,
        )
        ?.toList(growable: false);
    final tags =
        doc.maybeGetList<String>(ScoreFields.tags)?.toList(growable: false);

    if (title == null || createdAt == null || modifiedAt == null) {
      reportCorruptData(doc.data());
    }

    return Score(
      id: doc.id,
      title: title ?? 'unknown',
      subtitle: doc.maybeGet(ScoreFields.subtitle),
      dedication: doc.maybeGet(ScoreFields.dedication),
      createdAt: createdAt ?? DateTime.now(),
      modifiedAt: modifiedAt ?? DateTime.now(),
      composers: composers ?? const [],
      arrangements: arrangements ?? const [],
      tags: tags ?? const [],
    );
  }

  Arrangement? _mapToArrangement(Map<String, dynamic> json) {
    final name = json.maybeGet<String>(ArrangementFields.name);
    if (name == null) {
      return null;
    }
    final arrangers = json
        .maybeGetList<String>(ArrangementFields.arrangers)
        ?.toList(growable: false);
    final parts = json
        .maybeGetList<Map<String, dynamic>>(ArrangementFields.parts)
        ?.map(_mapToArrangementPart)
        .whereType<ArrangementPart>()
        .toList(growable: false);
    final lyricists = json
        .maybeGetList<String>(ArrangementFields.lyricists)
        ?.toList(growable: false);
    final description = json.maybeGet<String>(ArrangementFields.description);

    return Arrangement(
      name: name,
      arrangers: arrangers ?? const [],
      parts: parts ?? const [],
      lyricists: lyricists ?? const [],
      description: description,
    );
  }

  ArrangementPart? _mapToArrangementPart(Map<String, dynamic> json) {
    final links = json
        .maybeGetList<String>(ArrangementPartFields.links)
        ?.map(Uri.parse)
        .toList(growable: false);
    final instruments = json
        .maybeGetList<String>(ArrangementPartFields.targetInstrument)
        ?.map(Instrument.parse)
        .toList(growable: false);
    final description =
        json.maybeGet<String>(ArrangementPartFields.description);

    return ArrangementPart(
      links: links ?? const [],
      instruments: instruments ?? const [],
      description: description,
    );
  }

  Map<String, Object?> _scoreToDoc(Score score, SetOptions? options) {
    return {
      ScoreFields.title: score.title,
      if (score.subtitle != null) ScoreFields.subtitle: score.subtitle,
      if (score.dedication != null) ScoreFields.dedication: score.dedication,
      ScoreFields.createdAt: score.createdAt,
      ScoreFields.modifiedAt: score.modifiedAt,
      ScoreFields.composers: score.composers,
    };
  }

  Future<String> addScore(Score score) {
    return scoresCollection.add(score).then((ref) => ref.id);
  }
}

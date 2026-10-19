import 'package:score/features/notation/parts.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';
import 'package:songbird_musicxml/songbird_musicxml.dart';
import 'package:songbird_score/songbird_score.dart';

class ScoreViewController({
  required final ScoreController scoreController,
}) {
  factory ScoreViewController.forScore(
    Score score, {
    ScoreViewSettings settings = const ScoreViewSettings.defaultView(),
  }) {
    final controller = ScoreViewController(
      scoreController: ScoreController(
        score: _giveEveryPartItsOwnId(score),
        baseStaffSpace: 7.5,
        minZoom: ScoreViewSettings.minZoom,
        maxZoom: ScoreViewSettings.maxZoom,
      ),
    );
    controller.apply(settings);
    return controller;
  }

  List<ScorePartRef> get parts => readParts(scoreController.score);

  int get transposition => scoreController.transposition.chromaticSemitones;

  String get visibleMusicXml => const MusicXmlWriter().write(
    scoreController.score.withParts(scoreController.visibleParts),
  );

  bool isPartVisible(String partId) {
    final part = _part(partId);
    return part != null && scoreController.isPartVisible(part);
  }

  ScoreViewSettings get settings => ScoreViewSettings(
    transposition: transposition,
    hiddenParts: scoreController.score.parts
        .where((part) => !scoreController.isPartVisible(part))
        .map((part) => part.id)
        .toList(growable: false),
    zoom: scoreController.zoom,
  );

  void apply(ScoreViewSettings settings) {
    transposeTo(settings.transposition);
    final parts = scoreController.score.parts;
    if (parts.any((part) => !settings.isHidden(part.id))) {
      scoreController.showOnlyParts(
        parts.where((part) => !settings.isHidden(part.id)),
      );
    } else {
      scoreController.showAllParts();
    }
    scoreController.zoom = settings.zoom;
  }

  /// Transposing is a step rather than a setting — the score is moved by an
  /// interval, not told what key to be in — so going from down a tone to up a
  /// third means putting it back first. The controller knows how far it has
  /// been moved, which is what makes that one call rather than bookkeeping
  /// here.
  void transposeTo(int semitones) {
    final wanted = semitones.clamp(
      ScoreViewSettings.minTransposition,
      ScoreViewSettings.maxTransposition,
    );
    if (wanted == transposition) {
      return;
    }
    scoreController.resetTransposition();
    scoreController.transposeBySemitones(wanted);
  }

  void transposeBy(int semitones) => transposeTo(transposition + semitones);

  /// Hiding the last part that is left is refused rather than obeyed: a score
  /// with nothing on it is not a view of anything, and there would be no part
  /// left to click to get back.
  void setPartVisible(String partId, bool visible) {
    final part = _part(partId);
    if (part == null) {
      return;
    }
    if (!visible && scoreController.visibleParts.length <= 1) {
      return;
    }
    scoreController.setPartVisible(part, visible);
  }

  void showAsWritten() {
    transposeTo(0);
    scoreController.showAllParts();
  }

  void zoomIn() => scoreController.zoomIn();

  void zoomOut() => scoreController.zoomOut();

  void replaceScore(Score score) {
    final kept = settings;
    scoreController.replaceScore(_giveEveryPartItsOwnId(score));
    apply(kept);
  }

  void dispose() => scoreController.dispose();

  Part? _part(String partId) => scoreController.score.parts
      .where((part) => part.id == partId)
      .firstOrNull;

  /// Renames every part whose id is empty or taken to the one [readParts]
  /// names it by.
  ///
  /// The controller hides a part by its id, so two parts that share one would
  /// come and go together, while the view and the download both tell them
  /// apart by their place. The download "as on screen" is written from this
  /// score, so it carries these names too; the download as written does not.
  static Score _giveEveryPartItsOwnId(Score score) {
    final refs = readParts(score);
    for (var index = 0; index < score.parts.length; index++) {
      final part = score.parts[index];
      final id = refs[index].id;
      if (part.id == id) continue;
      score.parts[index] = Part(
        id: id,
        name: part.name,
        measures: part.measures,
        abbreviation: part.abbreviation,
        nameDisplay: part.nameDisplay,
        abbreviationDisplay: part.abbreviationDisplay,
        instruments: part.instruments,
        midiInstruments: part.midiInstruments,
        spanners: part.spanners,
        printName: part.printName,
        printAbbreviation: part.printAbbreviation,
      );
    }
    return score;
  }
}

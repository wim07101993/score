import 'package:score_backend/src/musicxml/models/enums.g.dart';
import 'package:score_backend/src/score_model/instrument.dart';

export 'instrument.dart';

sealed class PartListItem {}

class PartGroupStart implements PartListItem {
  const PartGroupStart({
    required this.number,
    required this.symbol,
  });

  final int number;
  final GroupSymbolValue symbol;
}

class PartGroupEnd implements PartListItem {
  const PartGroupEnd(this.number);

  final int number;
}

class ScorePart {
  const ScorePart({
    required this.name,
    this.displayName,
    this.abbreviation,
    this.abbreviationDisplay,
    required this.instruments,
  });

  final String name;
  final NameDisplay? displayName;
  final String? abbreviation;
  final NameDisplay? abbreviationDisplay;
  final List<Instrument> instruments;
}

class NameDisplay {
  const NameDisplay({
    required this.displayText,
    this.accidentalText,
    this.shouldPrint = true,
  });

  final String displayText;
  final String? accidentalText;
  final bool shouldPrint;
}

abstract class ArrangementPart {
  const ArrangementPart({
    required this.links,
    this.description,
  });

  final List<Uri> links;
  final String? description;
}

class SingerArrangementPart extends ArrangementPart {
  const SingerArrangementPart({
    required super.links,
    required this.lyricists,
    super.description,
  });

  final List<String> lyricists;
}

class ChoirArrangementPart extends ArrangementPart {
  const ChoirArrangementPart({
    required super.links,
    required this.lyricists,
    super.description,
  });

  final List<String> lyricists;
}

class GuitarArrangementPart extends ArrangementPart {
  const GuitarArrangementPart({
    required super.links,
    super.description,
  });
}

class PianoArrangementPart extends ArrangementPart {
  const PianoArrangementPart({
    required super.links,
    super.description,
  });
}

class FluteArrangementPart extends ArrangementPart {
  const FluteArrangementPart({
    required super.links,
    super.description,
  });
}

class ViolinArrangementPart extends ArrangementPart {
  const ViolinArrangementPart({
    required super.links,
    super.description,
  });
}

class CelloArrangementPart extends ArrangementPart {
  const CelloArrangementPart({
    required super.links,
    super.description,
  });
}

class ClarinetArrangementPart extends ArrangementPart {
  const ClarinetArrangementPart({
    required super.links,
    super.description,
  });
}

class TrumpetArrangementPart extends ArrangementPart {
  const TrumpetArrangementPart({
    required super.links,
    super.description,
  });
}

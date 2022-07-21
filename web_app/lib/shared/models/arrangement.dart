import 'package:score/shared/models/arrangement_part.dart';

class Arrangement {
  const Arrangement({
    required this.name,
    required this.arrangers,
    required this.parts,
  });

  final String name;
  final List<String> arrangers;
  final List<ArrangementPart> parts;
}

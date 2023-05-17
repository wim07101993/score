import 'package:score/features/score_search/models/part.dart';

class Score {
  Score({
    required this.title,
    required this.arrangementName,
    required this.alsoKnownAs,
    required this.composers,
    required this.lyricists,
    required this.parts,
  });

  final String title;
  final String? arrangementName;
  final List<String> alsoKnownAs;
  final List<String> composers;
  final List<String> lyricists;
  final List<Part> parts;

  Set<String> get creators => {...composers, ...lyricists};
  Set<String> get instruments =>
      parts.expand((part) => part.instruments).toSet();
}

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
  final String arrangementName;
  final List<String> alsoKnownAs;
  final List<String> composers;
  final List<String> lyricists;
  final List<Part> parts;
}

class Part {
  const Part({
    required this.name,
    required this.instruments,
    required this.files,
  });

  final String name;
  final List<String> instruments;
  final List<PartFile> files;
}

abstract class PartFile {}

class LinkedFile implements PartFile {
  const LinkedFile({
    required this.link,
  });

  final String link;
}

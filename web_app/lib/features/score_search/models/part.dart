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

  @override
  bool operator ==(Object other) {
    return other is LinkedFile && other.link == link;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ link.hashCode;
}

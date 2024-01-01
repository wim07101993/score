sealed class Creator {
  const factory Creator.lyricist(String value) = Lyricist;

  String get value;
}

class Lyricist implements Creator {
  const Lyricist(this.value);

  @override
  final String value;
}

class Arranger implements Creator {
  const Arranger(this.value);

  @override
  final String value;
}

class Composer implements Creator {
  const Composer(this.value);

  @override
  final String value;
}

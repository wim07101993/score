class Clef {
  const Clef({
    required this.sign,
    required this.line,
    this.octaveChange = 0,
    this.staffNumber = 0,
  });

  final ClefSign sign;
  final int line;
  final int octaveChange;
  final int staffNumber;
}

enum ClefSign { g, f, c, percussion, tab, jianpu, none }

class Instrument {
  const Instrument({
    required this.id,
    required this.name,
    this.abbreviation,
  });

  final String id;
  final String name;
  final String? abbreviation;
}

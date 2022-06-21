class Score {
  const Score({
    required this.title,
    required this.subtitle,
    required this.dedication,
    required this.composers,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String title;
  final String? subtitle;
  final String? dedication;

  final DateTime createdAt;
  final DateTime modifiedAt;

  final List<String> composers;
}

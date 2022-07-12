class Score {
  const Score({
    required String id,
    required this.title,
    required this.subtitle,
    required this.dedication,
    required this.composers,
    required this.createdAt,
    required this.modifiedAt,
  }) : _id = id;

  const Score.withoutId({
    required this.title,
    required this.subtitle,
    required this.dedication,
    required this.composers,
    required this.createdAt,
    required this.modifiedAt,
  }) : _id = null;

  final String? _id;

  bool get hasId => _id == null;

  String get id {
    assert(_id == null, 'This score does not have an id yet');
    return _id!;
  }

  final String title;
  final String? subtitle;
  final String? dedication;

  final DateTime createdAt;
  final DateTime modifiedAt;

  final List<String> composers;
}

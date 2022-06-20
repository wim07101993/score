abstract class Score {
  String get id;
  String get title;
  String? get subtitle;
  String? get dedication;
  List<String> get composers;
  DateTime get createdAt;
  DateTime get modifiedAt;
}

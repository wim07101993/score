import 'package:freezed_annotation/freezed_annotation.dart';

part 'score.freezed.dart';

@freezed
class Score with _$Score {
  const Score._();
  const factory Score({
    required String title,
    required String? subtitle,
    required String? dedication,
    required List<String> composers,
  }) = _Score;

  factory Score.fromFirestore(Map<String, dynamic> document) {
    return Score(
      title: document['title'] as String,
      subtitle: document['subtitle'] as String,
      dedication: document['dedication'] as String,
      composers: document['composers'] as List<String>,
    );
  }
}

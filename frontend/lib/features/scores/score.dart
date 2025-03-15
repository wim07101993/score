import 'package:score/features/scores/db_extensions.dart';
import 'package:score/shared/api/generated/searcher.pb.dart' as grpc;

class Score {
  const Score({
    required this.id,
    required this.work,
    required this.movement,
    required this.creators,
    required this.instruments,
    required this.languages,
    required this.tags,
    required this.lastChangedAt,
    required this.favouritedAt,
  });

  factory Score.fromGrpc(grpc.Score score) {
    return Score(
      id: score.id,
      work: Work.fromGrpc(score.work),
      movement: Movement.fromGrpc(score.movement),
      creators: Creators.fromGrpc(score.creators),
      instruments: score.instruments,
      languages: score.languages,
      tags: score.tags,
      lastChangedAt: score.lastChangeTimestamp.toDateTime(),
      favouritedAt: null,
    );
  }

  factory Score.fromDatabase(Map<String, dynamic> map) {
    return Score(
      id: map[Columns.id] as String,
      work: Work.fromDatabase(map),
      movement: Movement.fromDatabase(map),
      creators: Creators.fromDatabase(map),
      instruments: map[Columns.instruments] as List<String>? ?? [],
      languages: map[Columns.languages] as List<String>? ?? [],
      tags: map[Columns.tags] as List<String>? ?? [],
      lastChangedAt: DateTime.parse(map[Columns.lastChangedAt] as String),
      favouritedAt: map[Columns.favouritedAt] as DateTime?,
    );
  }

  final String id;
  final Work? work;
  final Movement? movement;
  final Creators creators;
  final List<String> instruments;
  final List<String> languages;
  final List<String> tags;
  final DateTime lastChangedAt;
  final DateTime? favouritedAt;
}

class Work {
  const Work({
    required this.title,
    required this.number,
  });

  static Work? fromGrpc(grpc.Work work) {
    return work.title.isEmpty && work.number.isEmpty
        ? null
        : Work(
            title: work.title,
            number: work.number,
          );
  }

  static Work? fromDatabase(Map<String, dynamic> map) {
    final title = map[Columns.workTitle] as String?;
    final number = map[Columns.workNumber] as String?;
    return title == null && number == null
        ? null
        : Work(title: title, number: number);
  }

  final String? title;
  final String? number;
}

class Movement {
  const Movement({
    required this.title,
    required this.number,
  });

  static Movement? fromGrpc(grpc.Movement work) {
    return work.title.isEmpty && work.number.isEmpty
        ? null
        : Movement(title: work.title, number: work.number);
  }

  static Movement? fromDatabase(Map<String, dynamic> map) {
    final title = map[Columns.movementTitle] as String?;
    final number = map[Columns.movementNumber] as String?;
    return title == null && number == null
        ? null
        : Movement(title: title, number: number);
  }

  final String? title;
  final String? number;
}

class Creators {
  const Creators({
    required this.composers,
    required this.lyricists,
  });

  factory Creators.fromGrpc(grpc.Creators creators) {
    return Creators(
      composers: creators.composers,
      lyricists: creators.lyricists,
    );
  }

  factory Creators.fromDatabase(Map<String, dynamic> map) {
    return Creators(
      composers: map[Columns.creatorsComposers] as List<String>? ?? [],
      lyricists: map[Columns.creatorsLyricists] as List<String>? ?? [],
    );
  }

  final List<String> composers;
  final List<String> lyricists;
}

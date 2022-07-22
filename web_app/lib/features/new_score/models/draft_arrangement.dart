import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/features/new_score/models/draft_arrangement_part.dart';
import 'package:score/shared/models/arrangement.dart';

part 'draft_arrangement.freezed.dart';

class DraftArrangement {
  DraftArrangement({
    required this.name,
    required this.arrangers,
    required this.lyricists,
    required this.parts,
    required this.description,
  }) {
    final errors = [
      ...validateName(name),
      ...validateArrangers(arrangers),
      ...validateLyricists(lyricists),
      ...validateParts(parts),
      ...validateDescription(description),
    ];
    if (errors.isNotEmpty) {
      throw Exception("Data for draft arrangement is not valid: $errors");
    }
  }

  static const int maxNameLength = 100;
  static const int maxNumberOfArrangers = 10;
  static const int maxArrangerLength = 100;
  static const int maxNumberOfLyricists = 10;
  static const int maxLyricistLength = 100;
  static const int maxNumberOfParts = 50;
  static const int maxDescriptionLength = 300;

  final String name;
  final List<String> arrangers;
  final List<DraftArrangementPart> parts;
  final List<String> lyricists;
  final String? description;

  Arrangement toArrangement() {
    return Arrangement(
      name: name,
      arrangers: arrangers,
      lyricists: lyricists,
      parts: parts
          .map((draft) => draft.toArrangementPart())
          .toList(growable: false),
    );
  }

  static Iterable<DraftArrangementError> validateName(String? name) sync* {
    if (name == null || name.isEmpty) {
      yield const DraftArrangementError.nameIsRequired();
    } else if (name.length > maxNameLength) {
      yield const DraftArrangementError.nameTooLong();
    }
  }

  static Iterable<DraftArrangementError> validateArrangers(
    List<String?> arrangers,
  ) sync* {
    if (arrangers.length > maxNumberOfArrangers) {
      yield const DraftArrangementError.tooManyArrangers();
    }
    for (final arranger in arrangers) {
      yield* validateArranger(arranger);
    }
  }

  static Iterable<DraftArrangementError> validateArranger(
    String? arranger,
  ) sync* {
    if (arranger == null || arranger.isEmpty) {
      yield const DraftArrangementError.arrangerMustHaveAName();
    } else if (arranger.length > maxArrangerLength) {
      yield const DraftArrangementError.arrangerNameTooLong();
    }
  }

  static Iterable<DraftArrangementError> validateParts(
    List<DraftArrangementPart?> parts,
  ) sync* {
    if (parts.length > maxNumberOfParts) {
      yield const DraftArrangementError.tooManyParts();
    }
  }

  static Iterable<DraftArrangementError> validateLyricists(
    List<String?> lyricists,
  ) sync* {
    if (lyricists.length > maxNumberOfLyricists) {
      yield const DraftArrangementError.tooManyLyricists();
    }
    for (final lyricist in lyricists) {
      yield* validateLyricist(lyricist);
    }
  }

  static Iterable<DraftArrangementError> validateLyricist(
    String? lyricist,
  ) sync* {
    if (lyricist == null || lyricist.isEmpty) {
      yield const DraftArrangementError.lyricistMustHaveAName();
    } else if (lyricist.length > maxLyricistLength) {
      yield const DraftArrangementError.lyricistNameTooLong();
    }
  }

  static Iterable<DraftArrangementError> validateDescription(
    String? description,
  ) sync* {
    if (description == null || description.isEmpty) {
      return;
    } else if (description.length > maxDescriptionLength) {
      yield const DraftArrangementError.descriptionTooLong();
    }
  }
}

@freezed
class DraftArrangementError with _$DraftArrangementError {
  const DraftArrangementError._();
  const factory DraftArrangementError.nameIsRequired() = _NameIsRequired;
  const factory DraftArrangementError.nameTooLong() = _NameTooLong;
  const factory DraftArrangementError.tooManyArrangers() = _TooManyArrangers;
  const factory DraftArrangementError.arrangerMustHaveAName() =
      _ArrangerMustHaveAName;
  const factory DraftArrangementError.arrangerNameTooLong() =
      _ArrangerNameTooLong;
  const factory DraftArrangementError.tooManyParts() = _TooManyParts;
  const factory DraftArrangementError.tooManyLyricists() = _TooManyLyricists;
  const factory DraftArrangementError.lyricistMustHaveAName() =
      _TooManyLyricists;
  const factory DraftArrangementError.lyricistNameTooLong() =
      _LyricistNameTooLong;
  const factory DraftArrangementError.descriptionTooLong() =
      _DescriptionTooLong;
}

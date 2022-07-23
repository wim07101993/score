import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/string_extensions.dart';

part 'score.freezed.dart';

mixin Score {
  static const int maxTitleLength = 100;
  static const int maxSubtitleLength = 100;
  static const int maxDedicationLength = 200;
  static const int maxNumberOfComposers = 10;
  static const int maxComposerLength = 100;
  static const int maxNumberOfTags = 200;
  static const int maxTagLength = 100;
  static const int maxNumberOfArrangements = 100;

  String get title;
  String? get subtitle;
  String? get dedication;
  DateTime get createdAt;
  DateTime get modifiedAt;
  List<String> get composers;
  List<Arrangement> get arrangements;
  List<String> get tags;

  Iterable<ScoreValidationError> validate() sync* {
    yield* validateTitle(title);
    yield* validateSubtitle(subtitle);
    yield* validateDedication(dedication);
    yield* validateCreatedAt(createdAt);
    yield* validateModifiedAt(modifiedAt);
    if (createdAt.isAfter(modifiedAt)) {
      yield const ScoreValidationError.createdAtCannotBeAfterModifiedAt();
    }
    yield* validateComposers(composers);
    yield* validateArrangements(arrangements);
    yield* validateTags(tags);
  }

  static Iterable<ScoreValidationError> validateTitle(String? title) sync* {
    if (title == null || title.isEmpty) {
      yield const ScoreValidationError.titleIsRequired();
    } else if (title.length > maxTitleLength) {
      yield const ScoreValidationError.titleTooLong();
    }
  }

  static Iterable<ScoreValidationError> validateSubtitle(
    String? subtitle,
  ) sync* {
    if (subtitle != null && subtitle.length > maxSubtitleLength) {
      yield const ScoreValidationError.subtitleTooLong();
    }
  }

  static Iterable<ScoreValidationError> validateDedication(
    String? dedication,
  ) sync* {
    if (dedication != null && dedication.length > maxDedicationLength) {
      yield const ScoreValidationError.dedicationTooLong();
    }
  }

  static Iterable<ScoreValidationError> validateComposers(
    List<String> composers,
  ) sync* {
    if (composers.length > maxNumberOfComposers) {
      yield const ScoreValidationError.tooManyComposers();
    }
    for (final composer in composers) {
      yield* validateComposer(composer);
    }
  }

  static Iterable<ScoreValidationError> validateComposer(
    String? composer,
  ) sync* {
    if (composer == null || composer.isEmpty) {
      yield const ScoreValidationError.composerMustHaveAName();
    } else if (composer.length > maxComposerLength) {
      yield const ScoreValidationError.composerNameTooLong();
    }
  }

  static Iterable<ScoreValidationError> validateTags(List<String?> tags) sync* {
    if (tags.length > maxNumberOfTags) {
      yield const ScoreValidationError.tooManyTags();
    }
    for (final tag in tags) {
      yield* validateTag(tag);
    }
  }

  static Iterable<ScoreValidationError> validateTag(String? tag) sync* {
    if (tag == null || tag.isEmpty) {
      yield const ScoreValidationError.tagMustHaveAValue();
    } else if (tag.length > maxTagLength) {
      yield const ScoreValidationError.tagTooLong();
    }
  }

  static Iterable<ScoreValidationError> validateArrangements(
    List<Arrangement> arrangements,
  ) sync* {
    if (arrangements.length > maxNumberOfTags) {
      yield const ScoreValidationError.tooManyArrangements();
    }
    if (arrangements.any((arrangement) => arrangement.validate().isNotEmpty)) {
      yield const ScoreValidationError.arrangementsNotValid();
    }
  }

  static Iterable<ScoreValidationError> validateCreatedAt(
    DateTime createdAt,
  ) sync* {
    if (createdAt.isAfter(DateTime.now())) {
      yield const ScoreValidationError.createdAtCannotBeInTheFuture();
    }
  }

  static Iterable<ScoreValidationError> validateModifiedAt(
    DateTime modifiedAt,
  ) sync* {
    if (modifiedAt.isAfter(DateTime.now())) {
      yield const ScoreValidationError.modifiedAtCannotBeInTheFuture();
    }
  }
}

class NewScore with Score {
  NewScore({
    required this.arrangements,
    required this.composers,
    required this.createdAt,
    required this.dedication,
    required this.modifiedAt,
    required this.subtitle,
    required this.tags,
    required this.title,
  }) {
    final errors = validate().toList(growable: false);
    if (errors.isNotEmpty) {
      throw Exception("Data for draft score is not valid: $errors");
    }
  }

  @override
  final List<Arrangement> arrangements;

  @override
  final List<String> composers;

  @override
  final DateTime createdAt;

  @override
  final String? dedication;

  @override
  final DateTime modifiedAt;

  @override
  final String? subtitle;

  @override
  final List<String> tags;

  @override
  final String title;
}

class SavedScore extends NewScore {
  SavedScore({
    required this.id,
    required super.title,
    required super.subtitle,
    required super.dedication,
    required super.composers,
    required super.createdAt,
    required super.modifiedAt,
    required super.arrangements,
    required super.tags,
  });

  static const int minIdLength = 10;
  static const int maxIdLength = 40;

  final String id;

  @override
  Iterable<ScoreValidationError> validate() sync* {
    yield* super.validate();
    yield* validateId(id);
  }

  static Iterable<ScoreValidationError> validateId(String? id) sync* {
    if (id == null || id.isEmpty) {
      yield const ScoreValidationError.idIsRequired();
    } else if (id.length < minIdLength) {
      yield const ScoreValidationError.idNotLongEnough();
    } else if (id.length > maxIdLength) {
      yield const ScoreValidationError.idIsTooLong();
    }
  }
}

class EditableScore extends ChangeNotifier with Score {
  EditableScore({
    required this.editableTitle,
    required this.editableSubtitle,
    required this.editableDedication,
    required this.editableComposers,
    required this.editableTags,
    required this.editableArrangements,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = DateTime.now();

  factory EditableScore.empty() {
    return EditableScore(
      editableTitle: TextEditingController(),
      editableSubtitle: TextEditingController(),
      editableDedication: TextEditingController(),
      editableComposers: List.empty(growable: true),
      editableTags: List.empty(growable: true),
      editableArrangements: List.empty(growable: true),
    );
  }

  final TextEditingController editableTitle;
  final TextEditingController editableSubtitle;
  final TextEditingController editableDedication;
  final List<TextEditingController> editableComposers;
  final List<TextEditingController> editableTags;
  final List<EditableArrangement> editableArrangements;

  @override
  String get title => editableTitle.text;

  @override
  String? get subtitle => editableSubtitle.text.nullIfEmpty();

  @override
  String? get dedication => editableDedication.text.nullIfEmpty();

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  List<Arrangement> get arrangements => editableArrangements;

  @override
  List<String> get composers {
    return editableComposers
        .map((editableComposer) => editableComposer.text)
        .toList(growable: false);
  }

  @override
  List<String> get tags {
    return editableTags
        .map((editableTag) => editableTag.text)
        .toList(growable: false);
  }
}

@freezed
class ScoreValidationError with _$ScoreValidationError {
  const factory ScoreValidationError.titleIsRequired() = _TitleIsRequired;
  const factory ScoreValidationError.titleTooLong() = _TitleTooLong;
  const factory ScoreValidationError.subtitleTooLong() = _SubtitleTooLong;
  const factory ScoreValidationError.dedicationTooLong() = _DedicationTooLong;
  const factory ScoreValidationError.tooManyComposers() = _TooManyComposers;
  const factory ScoreValidationError.composerMustHaveAName() =
      _ComposerMustHaveAName;
  const factory ScoreValidationError.composerNameTooLong() =
      _ComposerNameTooLong;
  const factory ScoreValidationError.tooManyTags() = _TooManyTags;
  const factory ScoreValidationError.tagMustHaveAValue() = _TagMustHaveAValue;
  const factory ScoreValidationError.tagTooLong() = _TagTooLong;
  const factory ScoreValidationError.tooManyArrangements() =
      _TooManyArrangements;
  const factory ScoreValidationError.createdAtCannotBeInTheFuture() =
      _CreatedAtCannotBeInTheFuture;
  const factory ScoreValidationError.modifiedAtCannotBeInTheFuture() =
      _ModifiedAtCannotBeInTheFuture;
  const factory ScoreValidationError.createdAtCannotBeAfterModifiedAt() =
      _CreatedAtCannotBeAfterModifiedAt;
  const factory ScoreValidationError.idIsRequired() = _IdIsRequired;
  const factory ScoreValidationError.idIsTooLong() = _IdIsTooLong;
  const factory ScoreValidationError.idNotLongEnough() = _IdNotLongEnough;
  const factory ScoreValidationError.arrangementsNotValid() =
      _arrangementsNotValid;

  // String getMessage(S s) {
  //   return 'Validation error';
  // TODO
  // return when(
  //   titleIsRequired: () => s.titleIsRequiredErrorMessage,
  //   titleTooLong: () => s.titleTooLongErrorMessage(DraftScore.maxTitleLength),
  //   subtitleTooLong: () {
  //     return s.subtitleTooLongErrorMessage(DraftScore.maxSubtitleLength);
  //   },
  //   dedicationTooLong: () {
  //     return s.dedicationTooLongErrorMessage(DraftScore.maxDedicationLength);
  //   },
  //   tooManyComposers: () {
  //     return s.tooManyComposersErrorMessage(DraftScore.maxNumberOfComposers);
  //   },
  //   composerMustHaveAName: () => s.composerMustHaveANameErrorMessage,
  //   composerNameTooLong: () {
  //     return s.composerNameTooLongErrorMessage(DraftScore.maxComposerLength);
  //   },
  // );
  // }
}

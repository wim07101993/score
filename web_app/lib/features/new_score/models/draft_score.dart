import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/features/new_score/models/draft_arrangement.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

part 'draft_score.freezed.dart';

class DraftScore {
  DraftScore({
    required this.title,
    required this.subtitle,
    required this.dedication,
    required this.composers,
    required this.tags,
    required this.arrangements,
  }) {
    final errors = [
      ...validateTitle(title),
      ...validateSubtitle(subtitle),
      ...validateDedication(dedication),
      ...validateComposers(composers),
      ...validateTags(tags),
      ...validateArrangements(arrangements),
    ];
    if (errors.isNotEmpty) {
      throw Exception("Data for draft score is not valid: $errors");
    }
  }

  static const int maxTitleLength = 100;
  static const int maxSubtitleLength = 100;
  static const int maxDedicationLength = 200;
  static const int maxNumberOfComposers = 10;
  static const int maxComposerLength = 100;
  static const int maxNumberOfTags = 200;
  static const int maxTagLength = 100;
  static const int maxNumberOfArrangements = 100;

  final String title;
  final String? subtitle;
  final String? dedication;
  final DateTime createdAt = DateTime.now().toUtc();
  final List<String> composers;
  final List<String> tags;
  final List<DraftArrangement> arrangements;

  Score toScore() {
    return Score.withoutId(
      title: title,
      subtitle: subtitle,
      dedication: dedication,
      composers: composers,
      createdAt: createdAt,
      modifiedAt: createdAt,
      tags: tags,
      arrangements: arrangements
          .map((draft) => draft.toArrangement())
          .toList(growable: false),
    );
  }

  static Iterable<DraftScoreError> validateTitle(String? title) sync* {
    if (title == null || title.isEmpty) {
      yield const DraftScoreError.titleIsRequired();
    } else if (title.length > maxTitleLength) {
      yield const DraftScoreError.titleTooLong();
    }
  }

  static Iterable<DraftScoreError> validateSubtitle(String? subtitle) sync* {
    if (subtitle != null && subtitle.length > maxSubtitleLength) {
      yield const DraftScoreError.subtitleTooLong();
    }
  }

  static Iterable<DraftScoreError> validateDedication(
    String? dedication,
  ) sync* {
    if (dedication != null && dedication.length > maxDedicationLength) {
      yield const DraftScoreError.dedicationTooLong();
    }
  }

  static Iterable<DraftScoreError> validateComposers(
    List<String> composers,
  ) sync* {
    if (composers.length > maxNumberOfComposers) {
      yield const DraftScoreError.tooManyComposers();
    }
    for (final composer in composers) {
      yield* validateComposer(composer);
    }
  }

  static Iterable<DraftScoreError> validateComposer(
    String? composer,
  ) sync* {
    if (composer == null || composer.isEmpty) {
      yield const DraftScoreError.composerMustHaveAName();
    } else if (composer.length > maxComposerLength) {
      yield const DraftScoreError.composerNameTooLong();
    }
  }

  static Iterable<DraftScoreError> validateTags(
    List<String?> tags,
  ) sync* {
    if (tags.length > maxNumberOfTags) {
      yield const DraftScoreError.tooManyTags();
    }
    for (final tag in tags) {
      yield* validateTag(tag);
    }
  }

  static Iterable<DraftScoreError> validateTag(
    String? tag,
  ) sync* {
    if (tag == null || tag.isEmpty) {
      yield const DraftScoreError.tagMustHaveAValue();
    } else if (tag.length > maxTagLength) {
      yield const DraftScoreError.tagTooLong();
    }
  }

  static Iterable<DraftScoreError> validateArrangements(
    List<DraftArrangement> arrangements,
  ) sync* {
    if (arrangements.length > maxNumberOfTags) {
      yield const DraftScoreError.tooManyArrangements();
    }
  }
}

@freezed
class DraftScoreError with _$DraftScoreError {
  const DraftScoreError._();
  const factory DraftScoreError.titleIsRequired() = _TitleIsRequired;
  const factory DraftScoreError.titleTooLong() = _TitleTooLong;
  const factory DraftScoreError.subtitleTooLong() = _SubtitleTooLong;
  const factory DraftScoreError.dedicationTooLong() = _DedicationTooLong;
  const factory DraftScoreError.tooManyComposers() = _TooManyComposers;
  const factory DraftScoreError.composerMustHaveAName() =
      _ComposerMustHaveAName;
  const factory DraftScoreError.composerNameTooLong() = _ComposerNameTooLong;
  const factory DraftScoreError.tooManyTags() = _TooManyTags;
  const factory DraftScoreError.tagMustHaveAValue() = _TagMustHaveAValue;
  const factory DraftScoreError.tagTooLong() = _TagTooLong;
  const factory DraftScoreError.tooManyArrangements() = _TooManyArrangements;

  String getMessage(S s) {
    return 'Validation error';
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
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

part 'draft_score.freezed.dart';

class DraftScore implements Score {
  DraftScore({
    required this.title,
    required this.subtitle,
    required this.dedication,
    required this.composers,
  }) {
    final errors = [
      ...validateTitle(title),
      ...validateSubtitle(subtitle),
      ...validateDedication(dedication),
      ...validateComposers(composers),
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

  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String? dedication;
  @override
  final List<String> composers;
  @override
  final DateTime createdAt = DateTime.now().toUtc();
  @override
  DateTime get modifiedAt => createdAt;

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
    List<String?> composers,
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
      yield const DraftScoreError.composerMutHaveAName();
    } else if (composer.length > maxComposerLength) {
      yield const DraftScoreError.composerNameTooLong();
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
  const factory DraftScoreError.composerMutHaveAName() = _ComposerMustHaveAName;
  const factory DraftScoreError.composerNameTooLong() = _ComposerNameTooLong;

  String getMessage(S s) {
    return when(
      titleIsRequired: () => s.titleIsRequiredErrorMessage,
      titleTooLong: () => s.titleTooLongErrorMessage(DraftScore.maxTitleLength),
      subtitleTooLong: () {
        return s.subtitleTooLongErrorMessage(DraftScore.maxSubtitleLength);
      },
      dedicationTooLong: () {
        return s.dedicationTooLongErrorMessage(DraftScore.maxDedicationLength);
      },
      tooManyComposers: () {
        return s.tooManyComposersErrorMessage(DraftScore.maxNumberOfComposers);
      },
      composerMutHaveAName: () => s.composerMustHaveANameErrorMessage,
      composerNameTooLong: () {
        return s.composerNameTooLongErrorMessage(DraftScore.maxComposerLength);
      },
    );
  }
}

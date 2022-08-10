import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/score.dart';

extension FutureExceptionOrExtensions<T> on Future<ExceptionOr<T>> {
  Future<void> handleException(
    BuildContext context, [
    Future<void> Function(Exception exception)? action,
  ]) {
    final s = S.of(context)!;
    if (action != null) {
      return thenWhen(action, (value) {});
    }
    return thenWhen(
      (exception) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translateException(s, exception))),
      ),
      (value) {},
    );
  }
}

String translateException(S s, Exception exception) {
  return s.genericErrorMessage;
}

extension TranslationExtensions on S {
  String getErrorMessage(dynamic e) {
    if (e is ScoreValidationError) {
      return e.when(
        titleIsRequired: () => titleIsRequiredErrorMessage,
        titleTooLong: () => titleTooLongErrorMessage(Score.maxTitleLength),
        subtitleTooLong: () =>
            subtitleTooLongErrorMessage(Score.maxSubtitleLength),
        dedicationTooLong: () =>
            dedicationTooLongErrorMessage(Score.maxDedicationLength),
        tooManyComposers: () =>
            tooManyComposersErrorMessage(Score.maxNumberOfComposers),
        composerMustHaveAName: () => composerMustHaveANameErrorMessage,
        composerNameTooLong: () =>
            composerNameTooLongErrorMessage(Score.maxComposerLength),
        tooManyTags: () => tooManyTagsErrorMessage(Score.maxNumberOfTags),
        tagMustHaveAValue: () => tagMustHaveAValueErrorMessage,
        tagTooLong: () => tagTooLongErrorMessage(Score.maxTagLength),
        tooManyArrangements: () =>
            tooManyArrangementsErrorMessage(Score.maxNumberOfArrangements),
        createdAtCannotBeInTheFuture: () => genericErrorMessage,
        modifiedAtCannotBeInTheFuture: () => genericErrorMessage,
        createdAtCannotBeAfterModifiedAt: () => genericErrorMessage,
        idIsRequired: () => genericErrorMessage,
        idIsTooLong: () => genericErrorMessage,
        idNotLongEnough: () => genericErrorMessage,
        arrangementsNotValid: () => arrangementsNotValidErrorMessage,
      );
    } else if (e is ArrangementValidationError) {
      return e.when(
        nameIsRequired: () => nameIsRequiredErrorMessage,
        nameTooLong: () => nameTooLongErrorMessage(Arrangement.maxNameLength),
        tooManyArrangers: () =>
            tooManyArrangersErrorMessage(Arrangement.maxNumberOfArrangers),
        arrangerMustHaveAName: () => arrangerMustHaveANameErrorMessage,
        arrangerNameTooLong: () =>
            arrangerNameTooLongErrorMessage(Arrangement.maxArrangerLength),
        tooManyParts: () =>
            tooManyPartsErrorMessage(Arrangement.maxNumberOfParts),
        tooManyLyricists: () =>
            tooManyLyricistsErrorMessage(Arrangement.maxNumberOfLyricists),
        lyricistMustHaveAName: () => lyricistMustHaveANameErrorMessage,
        lyricistNameTooLong: () =>
            lyricistNameTooLongErrorMessage(Arrangement.maxLyricistLength),
        descriptionTooLong: () =>
            descriptionTooLongErrorMessage(Arrangement.maxDescriptionLength),
        partsNotValid: () => partsNotValidErrorMessage,
      );
    } else if (e is ArrangementPartValidationError) {
      return e.when(
        tooManyLinks: () =>
            tooManyLinksErrorMessage(ArrangementPart.maxNumberOfLinks),
        linkMustHaveAValue: () => linkMustHaveAValueErrorMessage,
        linkTooLong: () =>
            linkTooLongErrorMessage(ArrangementPart.maxLinkLength),
        descriptionTooLong: () => descriptionTooLongErrorMessage(
            ArrangementPart.maxDescriptionLength),
        // TODO translation
        instrumentMustHaveAValue: () => 's.instrument must have a value',
        tooManyInstruments: () => tooManyInstrumentsErrorMessage(
            ArrangementPart.maxNumberOfInstruments),
      );
    } else {
      return genericErrorMessage;
    }
  }
}

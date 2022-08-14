import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/instrument.dart';
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
        instrumentMustHaveAValue: () => noInstrumentSelectedErrorMessage,
        tooManyInstruments: () => tooManyInstrumentsErrorMessage(
            ArrangementPart.maxNumberOfInstruments),
      );
    } else {
      return genericErrorMessage;
    }
  }

  String getInstrumentName(Instrument e) {
    switch (e) {
      case Instrument.unknown:
        return unknownInstrument;
      case Instrument.guitar:
        return guitar;
      case Instrument.bassGuitar:
        return bassGuitar;
      case Instrument.violin:
        return violin;
      case Instrument.tenorViolin:
        return tenorViolin;
      case Instrument.viola:
        return viola;
      case Instrument.cello:
        return cello;
      case Instrument.doubleBass:
        return doubleBass;
      case Instrument.harp:
        return harp;
      case Instrument.lute:
        return lute;
      case Instrument.piano:
        return piano;
      case Instrument.organ:
        return organ;
      case Instrument.accordion:
        return accordion;
      case Instrument.flute:
        return flute;
      case Instrument.altoFlute:
        return altoFlute;
      case Instrument.piccolo:
        return piccolo;
      case Instrument.recorder:
        return recorder;
      case Instrument.clarinet:
        return clarinet;
      case Instrument.altoClarinet:
        return altoClarinet;
      case Instrument.bassClarinet:
        return bassClarinet;
      case Instrument.bagpipes:
        return bagpipes;
      case Instrument.saxophone:
        return saxophone;
      case Instrument.sopranoSaxophone:
        return sopranoSaxophone;
      case Instrument.altoSaxophone:
        return altoSaxophone;
      case Instrument.tenorSaxophone:
        return tenorSaxophone;
      case Instrument.baritoneSaxophone:
        return baritoneSaxophone;
      case Instrument.bassSaxophone:
        return bassSaxophone;
      case Instrument.bassoon:
        return bassoon;
      case Instrument.contrabassoon:
        return contraBassoon;
      case Instrument.tenoroon:
        return tenoroon;
      case Instrument.oboe:
        return oboe;
      case Instrument.trumpet:
        return trumpet;
      case Instrument.frenchHorn:
        return frenchHorn;
      case Instrument.englishHorn:
        return englishHorn;
      case Instrument.altoHorn:
        return altoHorn;
      case Instrument.baritoneHorn:
        return baritoneHorn;
      case Instrument.trombone:
        return trombone;
      case Instrument.euphonium:
        return euphonium;
      case Instrument.tuba:
        return tuba;
      case Instrument.singer:
        return singer;
      case Instrument.choir:
        return choir;
      case Instrument.sopranoSinger:
        return sopranoSinger;
      case Instrument.alto:
        return alto;
      case Instrument.tenor:
        return tenor;
      case Instrument.baritone:
        return baritone;
      case Instrument.bass:
        return bass;
      case Instrument.tenorDrum:
        return tenorDrum;
      case Instrument.bassDrum:
        return bassDrum;
      case Instrument.xylophone:
        return xylophone;
    }
  }
}

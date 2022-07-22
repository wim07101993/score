import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/shared/models/arrangement.dart';

part 'draft_arrangement_part.freezed.dart';

class DraftArrangementPart {
  DraftArrangementPart({
    required this.links,
    required this.instruments,
    this.description,
  }) {
    final errors = [
      ...validateLinks(
        links.map((link) => link.toString()).toList(growable: false),
      ),
      ...validateDescription(description),
      ...validateInstruments(instruments),
    ];
    if (errors.isNotEmpty) {
      throw Exception("Data for draft arrangement part is not valid: $errors");
    }
  }

  static const int maxNumberOfLinks = 10;
  static const int maxLinkLength = 2048;
  static const int maxNumberOfInstruments = 10;
  static const int maxDescriptionLength = 300;

  final List<Uri> links;
  final String? description;
  final List<Instrument> instruments;

  ArrangementPart toArrangementPart() {
    return ArrangementPart(
      links: links,
      instruments: instruments,
    );
  }

  static Iterable<DraftArrangementPartError> validateLinks(
    List<String?> links,
  ) sync* {
    if (links.length > maxNumberOfLinks) {
      yield const DraftArrangementPartError.tooManyLinks();
    }
    for (final link in links) {
      yield* validateLink(link);
    }
  }

  static Iterable<DraftArrangementPartError> validateLink(
    String? link,
  ) sync* {
    if (link == null || link.isEmpty) {
      yield const DraftArrangementPartError.linkMustHaveAValue();
    } else if (link.length > maxLinkLength) {
      yield const DraftArrangementPartError.linkTooLong();
    }
  }

  static Iterable<DraftArrangementPartError> validateDescription(
    String? description,
  ) sync* {
    if (description == null) {
      return;
    } else if (description.length > maxLinkLength) {
      yield const DraftArrangementPartError.descriptionTooLong();
    }
  }

  static Iterable<DraftArrangementPartError> validateInstruments(
    List<Instrument> instruments,
  ) sync* {
    if (instruments.length > maxNumberOfLinks) {
      yield const DraftArrangementPartError.tooManyInstruments();
    }
  }
}

@freezed
class DraftArrangementPartError with _$DraftArrangementPartError {
  const DraftArrangementPartError._();
  const factory DraftArrangementPartError.tooManyLinks() = _TooManyLinks;
  const factory DraftArrangementPartError.linkMustHaveAValue() =
      _LinkMustHaveAValue;
  const factory DraftArrangementPartError.linkTooLong() = _LinkTooLong;
  const factory DraftArrangementPartError.descriptionTooLong() =
      _DescriptionTooLong;
  const factory DraftArrangementPartError.tooManyInstruments() =
      _TooManyInstruments;
}

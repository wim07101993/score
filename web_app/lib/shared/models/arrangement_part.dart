import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/shared/list_notifier.dart';
import 'package:score/shared/models/instrument.dart';
import 'package:score/shared/string_extensions.dart';

part 'arrangement_part.freezed.dart';

mixin ArrangementPart {
  static const int maxNumberOfLinks = 10;
  static const int maxLinkLength = 2048;
  static const int maxNumberOfInstruments = 10;
  static const int maxDescriptionLength = 300;

  List<Uri> get links;
  String? get description;
  List<Instrument> get instruments;

  Iterable<ArrangementPartValidationError> validate() sync* {
    yield* validateLinks(
      links.map((link) => link.toString()).toList(growable: false),
    );
    yield* validateDescription(description);
    yield* validateInstruments(instruments);
  }

  static Iterable<ArrangementPartValidationError> validateLinks(
    List<String?> links,
  ) sync* {
    if (links.length > maxNumberOfLinks) {
      yield const ArrangementPartValidationError.tooManyLinks();
    }
    for (final link in links) {
      yield* validateLink(link);
    }
  }

  static Iterable<ArrangementPartValidationError> validateLink(
    String? link,
  ) sync* {
    if (link == null || link.isEmpty) {
      yield const ArrangementPartValidationError.linkMustHaveAValue();
    } else if (link.length > maxLinkLength) {
      yield const ArrangementPartValidationError.linkTooLong();
    }
  }

  static Iterable<ArrangementPartValidationError> validateDescription(
    String? description,
  ) sync* {
    if (description == null) {
      return;
    } else if (description.length > maxLinkLength) {
      yield const ArrangementPartValidationError.descriptionTooLong();
    }
  }

  static Iterable<ArrangementPartValidationError> validateInstrument(
    Instrument? instrument,
  ) sync* {
    if (instrument == null) {
      yield const ArrangementPartValidationError.instrumentMustHaveAValue();
    }
  }

  static Iterable<ArrangementPartValidationError> validateInstruments(
    List<Instrument> instruments,
  ) sync* {
    if (instruments.length > maxNumberOfLinks) {
      yield const ArrangementPartValidationError.tooManyInstruments();
    }
  }
}

class NewArrangementPart with ArrangementPart {
  NewArrangementPart({
    required this.links,
    required this.description,
    required this.instruments,
  }) {
    final errors = validate().toList(growable: false);
    if (errors.isNotEmpty) {
      throw Exception("Data for arrangement part is not valid: $errors");
    }
  }

  @override
  final List<Uri> links;
  @override
  final String? description;
  @override
  final List<Instrument> instruments;
}

class SavedArrangementPart extends NewArrangementPart {
  SavedArrangementPart({
    required super.links,
    required super.description,
    required super.instruments,
  });
}

class EditableArrangementPart with ArrangementPart {
  EditableArrangementPart({
    required this.editableDescription,
    required this.editableInstruments,
    required this.editableLinks,
  });

  factory EditableArrangementPart.empty() {
    return EditableArrangementPart(
      editableDescription: TextEditingController(),
      editableInstruments:
          ListNotifier.empty(maxLength: ArrangementPart.maxNumberOfInstruments),
      editableLinks:
          ListNotifier.empty(maxLength: ArrangementPart.maxNumberOfLinks),
    );
  }

  final TextEditingController editableDescription;
  final ListNotifier<ValueNotifier<Instrument>> editableInstruments;
  final ListNotifier<TextEditingController> editableLinks;

  @override
  String? get description => editableDescription.text.nullIfEmpty();

  @override
  List<Uri> get links {
    return editableLinks.value
        .map((link) => Uri.parse(link.text))
        .toList(growable: false);
  }

  @override
  List<Instrument> get instruments {
    return editableInstruments.value
        .map((e) => e.value)
        .toList(growable: false);
  }
}

@freezed
class ArrangementPartValidationError with _$ArrangementPartValidationError {
  const ArrangementPartValidationError._();
  const factory ArrangementPartValidationError.tooManyLinks() = _TooManyLinks;
  const factory ArrangementPartValidationError.linkMustHaveAValue() =
      _LinkMustHaveAValue;
  const factory ArrangementPartValidationError.linkTooLong() = _LinkTooLong;
  const factory ArrangementPartValidationError.descriptionTooLong() =
      _DescriptionTooLong;
  const factory ArrangementPartValidationError.instrumentMustHaveAValue() =
      _InstrumentMustHaveAValue;
  const factory ArrangementPartValidationError.tooManyInstruments() =
      _TooManyInstruments;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/shared/list_notifier.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/string_extensions.dart';

part 'arrangement.freezed.dart';

mixin Arrangement {
  static const int maxNameLength = 100;
  static const int maxNumberOfArrangers = 10;
  static const int maxArrangerLength = 100;
  static const int maxNumberOfLyricists = 10;
  static const int maxLyricistLength = 100;
  static const int maxNumberOfParts = 50;
  static const int maxDescriptionLength = 300;

  String get name;
  List<String> get arrangers;
  List<ArrangementPart> get parts;
  List<String> get lyricists;
  String? get description;

  Iterable<ArrangementValidationError> validate() sync* {
    yield* validateName(name);
    yield* validateArrangers(arrangers);
    yield* validateParts(parts);
    yield* validateLyricists(lyricists);
    yield* validateDescription(description);
  }

  static Iterable<ArrangementValidationError> validateName(String? name) sync* {
    if (name == null || name.isEmpty) {
      yield const ArrangementValidationError.nameIsRequired();
    } else if (name.length > maxNameLength) {
      yield const ArrangementValidationError.nameTooLong();
    }
  }

  static Iterable<ArrangementValidationError> validateArrangers(
    List<String?> arrangers,
  ) sync* {
    if (arrangers.length > maxNumberOfArrangers) {
      yield const ArrangementValidationError.tooManyArrangers();
    }
    for (final arranger in arrangers) {
      yield* validateArranger(arranger);
    }
  }

  static Iterable<ArrangementValidationError> validateArranger(
    String? arranger,
  ) sync* {
    if (arranger == null || arranger.isEmpty) {
      yield const ArrangementValidationError.arrangerMustHaveAName();
    } else if (arranger.length > maxArrangerLength) {
      yield const ArrangementValidationError.arrangerNameTooLong();
    }
  }

  static Iterable<ArrangementValidationError> validateParts(
    List<ArrangementPart> parts,
  ) sync* {
    if (parts.length > maxNumberOfParts) {
      yield const ArrangementValidationError.tooManyParts();
    }
    if (parts.any((part) => part.validate().isNotEmpty)) {
      yield const ArrangementValidationError.partsNotValid();
    }
  }

  static Iterable<ArrangementValidationError> validateLyricists(
    List<String?> lyricists,
  ) sync* {
    if (lyricists.length > maxNumberOfLyricists) {
      yield const ArrangementValidationError.tooManyLyricists();
    }
    for (final lyricist in lyricists) {
      yield* validateLyricist(lyricist);
    }
  }

  static Iterable<ArrangementValidationError> validateLyricist(
    String? lyricist,
  ) sync* {
    if (lyricist == null || lyricist.isEmpty) {
      yield const ArrangementValidationError.lyricistMustHaveAName();
    } else if (lyricist.length > maxLyricistLength) {
      yield const ArrangementValidationError.lyricistNameTooLong();
    }
  }

  static Iterable<ArrangementValidationError> validateDescription(
    String? description,
  ) sync* {
    if (description == null || description.isEmpty) {
      return;
    } else if (description.length > maxDescriptionLength) {
      yield const ArrangementValidationError.descriptionTooLong();
    }
  }
}

class NewArrangement with Arrangement {
  NewArrangement({
    required this.name,
    required this.arrangers,
    required this.lyricists,
    required this.parts,
    this.description,
  }) {
    final errors = validate().toList(growable: false);
    if (errors.isNotEmpty) {
      throw Exception("Data for arrangement is not valid: $errors");
    }
  }

  @override
  final String name;
  @override
  final List<String> arrangers;
  @override
  final List<ArrangementPart> parts;
  @override
  final List<String> lyricists;
  @override
  final String? description;
}

class SavedArrangement extends NewArrangement {
  SavedArrangement({
    required super.name,
    required super.arrangers,
    required super.lyricists,
    required super.parts,
    super.description,
  });
}

class EditableArrangement with Arrangement {
  EditableArrangement({
    required this.editableName,
    required this.editableDescription,
    required this.editableArrangers,
    required this.editableLyricists,
    required this.editableParts,
  });

  factory EditableArrangement.empty() {
    return EditableArrangement(
      editableName: TextEditingController(),
      editableDescription: TextEditingController(),
      editableArrangers: ListNotifier.empty(),
      editableLyricists: ListNotifier.empty(),
      editableParts: ListNotifier.empty(),
    );
  }

  final TextEditingController editableName;
  final TextEditingController editableDescription;
  final ListNotifier<TextEditingController> editableArrangers;
  final ListNotifier<TextEditingController> editableLyricists;
  final ListNotifier<EditableArrangementPart> editableParts;

  @override
  String get name => editableName.text;

  @override
  String? get description => editableDescription.text.nullIfEmpty();

  @override
  List<String> get arrangers {
    return editableArrangers.value
        .map((editableArranger) => editableArranger.text)
        .toList(growable: false);
  }

  @override
  List<String> get lyricists {
    return editableLyricists.value
        .map((editableLyricist) => editableLyricist.text)
        .toList(growable: false);
  }

  @override
  List<ArrangementPart> get parts => editableParts.value;
}

@freezed
class ArrangementValidationError with _$ArrangementValidationError {
  const ArrangementValidationError._();
  const factory ArrangementValidationError.nameIsRequired() = _NameIsRequired;
  const factory ArrangementValidationError.nameTooLong() = _NameTooLong;
  const factory ArrangementValidationError.tooManyArrangers() =
      _TooManyArrangers;
  const factory ArrangementValidationError.arrangerMustHaveAName() =
      _ArrangerMustHaveAName;
  const factory ArrangementValidationError.arrangerNameTooLong() =
      _ArrangerNameTooLong;
  const factory ArrangementValidationError.tooManyParts() = _TooManyParts;
  const factory ArrangementValidationError.tooManyLyricists() =
      _TooManyLyricists;
  const factory ArrangementValidationError.lyricistMustHaveAName() =
      _LyricistMustHaveAName;
  const factory ArrangementValidationError.lyricistNameTooLong() =
      _LyricistNameTooLong;
  const factory ArrangementValidationError.descriptionTooLong() =
      _DescriptionTooLong;
  const factory ArrangementValidationError.partsNotValid() = _PartsNotValid;
}

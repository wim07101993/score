// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'score.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$Score implements TypedDocumentObject<MutableScore> {
  String get id;

  Work? get work;

  Movement? get movement;

  Creators get creators;

  List<String> get instruments;

  List<String> get languages;

  List<String> get tags;

  DateTime get lastChangeTimestamp;

  bool get isFavourite;
}

abstract class _ScoreImplBase<I extends Document>
    with _$Score
    implements Score {
  _ScoreImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  DateTime get lastChangeTimestamp => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'lastChangeTimestamp',
        key: 'lastChangeTimestamp',
        converter: TypedDataHelpers.dateTimeConverter,
      );

  @override
  bool get isFavourite => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'isFavourite',
        key: 'isFavourite',
        converter: TypedDataHelpers.boolConverter,
      );

  @override
  MutableScore toMutable() => MutableScore.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'Score',
        fields: {
          'id': id,
          'work': work,
          'movement': movement,
          'creators': creators,
          'instruments': instruments,
          'languages': languages,
          'tags': tags,
          'lastChangeTimestamp': lastChangeTimestamp,
          'isFavourite': isFavourite,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableScore extends _ScoreImplBase {
  ImmutableScore.internal(super.internal);

  static const _workConverter = const TypedDictionaryConverter<Dictionary, Work,
      TypedDictionaryObject<Work>>(ImmutableWork.internal);

  static const _movementConverter = const TypedDictionaryConverter<Dictionary,
      Movement, TypedDictionaryObject<Movement>>(ImmutableMovement.internal);

  static const _creatorsConverter = const TypedDictionaryConverter<Dictionary,
      Creators, TypedDictionaryObject<Creators>>(ImmutableCreators.internal);

  static const _instrumentsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _languagesConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _tagsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  @override
  late final work = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'work',
    key: 'work',
    converter: _workConverter,
  );

  @override
  late final movement = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'movement',
    key: 'movement',
    converter: _movementConverter,
  );

  @override
  late final creators = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'creators',
    key: 'creators',
    converter: _creatorsConverter,
  );

  @override
  late final instruments = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'instruments',
    key: 'instruments',
    converter: _instrumentsConverter,
  );

  @override
  late final languages = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'languages',
    key: 'languages',
    converter: _languagesConverter,
  );

  @override
  late final tags = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'tags',
    key: 'tags',
    converter: _tagsConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Score &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [Score].
class MutableScore extends _ScoreImplBase<MutableDocument>
    implements TypedMutableDocumentObject<Score, MutableScore> {
  /// Creates a new mutable [Score].
  MutableScore({
    required String id,
    required Work? work,
    required Movement? movement,
    required Creators creators,
    required List<String> instruments,
    required List<String> languages,
    required List<String> tags,
    required DateTime lastChangeTimestamp,
    required bool isFavourite,
  }) : super(MutableDocument.withId(id)) {
    if (work != null) {
      this.work = work;
    }
    if (movement != null) {
      this.movement = movement;
    }
    this.creators = creators;
    this.instruments = instruments;
    this.languages = languages;
    this.tags = tags;
    this.lastChangeTimestamp = lastChangeTimestamp;
    this.isFavourite = isFavourite;
  }

  MutableScore.internal(super.internal);

  static const _workConverter =
      const TypedDictionaryConverter<MutableDictionary, MutableWork, Work>(
          MutableWork.internal);

  static const _movementConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableMovement, Movement>(MutableMovement.internal);

  static const _creatorsConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableCreators, Creators>(MutableCreators.internal);

  static const _instrumentsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _languagesConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _tagsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  late MutableWork? _work = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'work',
    key: 'work',
    converter: _workConverter,
  );

  @override
  MutableWork? get work => _work;

  set work(Work? value) {
    final promoted = value == null ? null : _workConverter.promote(value);
    _work = promoted;
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'work',
      value: promoted,
      converter: _workConverter,
    );
  }

  late MutableMovement? _movement = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'movement',
    key: 'movement',
    converter: _movementConverter,
  );

  @override
  MutableMovement? get movement => _movement;

  set movement(Movement? value) {
    final promoted = value == null ? null : _movementConverter.promote(value);
    _movement = promoted;
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'movement',
      value: promoted,
      converter: _movementConverter,
    );
  }

  late MutableCreators _creators = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'creators',
    key: 'creators',
    converter: _creatorsConverter,
  );

  @override
  MutableCreators get creators => _creators;

  set creators(Creators value) {
    final promoted = _creatorsConverter.promote(value);
    _creators = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'creators',
      value: promoted,
      converter: _creatorsConverter,
    );
  }

  late TypedDataList<String, String> _instruments =
      TypedDataHelpers.readProperty(
    internal: internal,
    name: 'instruments',
    key: 'instruments',
    converter: _instrumentsConverter,
  );

  @override
  TypedDataList<String, String> get instruments => _instruments;

  set instruments(List<String> value) {
    final promoted = _instrumentsConverter.promote(value);
    _instruments = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'instruments',
      value: promoted,
      converter: _instrumentsConverter,
    );
  }

  late TypedDataList<String, String> _languages = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'languages',
    key: 'languages',
    converter: _languagesConverter,
  );

  @override
  TypedDataList<String, String> get languages => _languages;

  set languages(List<String> value) {
    final promoted = _languagesConverter.promote(value);
    _languages = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'languages',
      value: promoted,
      converter: _languagesConverter,
    );
  }

  late TypedDataList<String, String> _tags = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'tags',
    key: 'tags',
    converter: _tagsConverter,
  );

  @override
  TypedDataList<String, String> get tags => _tags;

  set tags(List<String> value) {
    final promoted = _tagsConverter.promote(value);
    _tags = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'tags',
      value: promoted,
      converter: _tagsConverter,
    );
  }

  set lastChangeTimestamp(DateTime value) {
    final promoted = TypedDataHelpers.dateTimeConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'lastChangeTimestamp',
      value: promoted,
      converter: TypedDataHelpers.dateTimeConverter,
    );
  }

  set isFavourite(bool value) {
    final promoted = TypedDataHelpers.boolConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'isFavourite',
      value: promoted,
      converter: TypedDataHelpers.boolConverter,
    );
  }
}

mixin _$Work implements TypedDocumentObject<MutableWork> {
  String get title;

  String get number;
}

abstract class _WorkImplBase<I extends Document> with _$Work implements Work {
  _WorkImplBase(this.internal);

  @override
  final I internal;

  @override
  String get title => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'title',
        key: 'title',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String get number => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'number',
        key: 'number',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableWork toMutable() => MutableWork.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'Work',
        fields: {
          'title': title,
          'number': number,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableWork extends _WorkImplBase {
  ImmutableWork.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Work &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [Work].
class MutableWork extends _WorkImplBase<MutableDocument>
    implements TypedMutableDocumentObject<Work, MutableWork> {
  /// Creates a new mutable [Work].
  MutableWork({
    required String title,
    required String number,
  }) : super(MutableDocument()) {
    this.title = title;
    this.number = number;
  }

  MutableWork.internal(super.internal);

  set title(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'title',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set number(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'number',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$Movement implements TypedDocumentObject<MutableMovement> {
  String get title;

  String get number;
}

abstract class _MovementImplBase<I extends Document>
    with _$Movement
    implements Movement {
  _MovementImplBase(this.internal);

  @override
  final I internal;

  @override
  String get title => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'title',
        key: 'title',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String get number => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'number',
        key: 'number',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableMovement toMutable() => MutableMovement.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'Movement',
        fields: {
          'title': title,
          'number': number,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableMovement extends _MovementImplBase {
  ImmutableMovement.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movement &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [Movement].
class MutableMovement extends _MovementImplBase<MutableDocument>
    implements TypedMutableDocumentObject<Movement, MutableMovement> {
  /// Creates a new mutable [Movement].
  MutableMovement({
    required String title,
    required String number,
  }) : super(MutableDocument()) {
    this.title = title;
    this.number = number;
  }

  MutableMovement.internal(super.internal);

  set title(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'title',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set number(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'number',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$Creators implements TypedDocumentObject<MutableCreators> {
  List<String> get composers;

  List<String> get lyricists;
}

abstract class _CreatorsImplBase<I extends Document>
    with _$Creators
    implements Creators {
  _CreatorsImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableCreators toMutable() => MutableCreators.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'Creators',
        fields: {
          'composers': composers,
          'lyricists': lyricists,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableCreators extends _CreatorsImplBase {
  ImmutableCreators.internal(super.internal);

  static const _composersConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _lyricistsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  @override
  late final composers = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'composers',
    key: 'composers',
    converter: _composersConverter,
  );

  @override
  late final lyricists = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'lyricists',
    key: 'lyricists',
    converter: _lyricistsConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Creators &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [Creators].
class MutableCreators extends _CreatorsImplBase<MutableDocument>
    implements TypedMutableDocumentObject<Creators, MutableCreators> {
  /// Creates a new mutable [Creators].
  MutableCreators({
    required List<String> composers,
    required List<String> lyricists,
  }) : super(MutableDocument()) {
    this.composers = composers;
    this.lyricists = lyricists;
  }

  MutableCreators.internal(super.internal);

  static const _composersConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  static const _lyricistsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  late TypedDataList<String, String> _composers = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'composers',
    key: 'composers',
    converter: _composersConverter,
  );

  @override
  TypedDataList<String, String> get composers => _composers;

  set composers(List<String> value) {
    final promoted = _composersConverter.promote(value);
    _composers = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'composers',
      value: promoted,
      converter: _composersConverter,
    );
  }

  late TypedDataList<String, String> _lyricists = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'lyricists',
    key: 'lyricists',
    converter: _lyricistsConverter,
  );

  @override
  TypedDataList<String, String> get lyricists => _lyricists;

  set lyricists(List<String> value) {
    final promoted = _lyricistsConverter.promote(value);
    _lyricists = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'lyricists',
      value: promoted,
      converter: _lyricistsConverter,
    );
  }
}

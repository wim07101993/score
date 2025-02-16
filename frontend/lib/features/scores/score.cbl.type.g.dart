// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'score.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$Score implements TypedDocumentObject<MutableScore> {
  String get id;

  String get title;

  List<String> get composers;

  List<String> get lyricists;

  List<String> get instruments;

  bool get isFavourite;

  DateTime get lastChangeTimestamp;
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
  String get title => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'title',
        key: 'title',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  bool get isFavourite => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'isFavourite',
        key: 'isFavourite',
        converter: TypedDataHelpers.boolConverter,
      );

  @override
  DateTime get lastChangeTimestamp => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'lastChangeTimestamp',
        key: 'lastChangeTimestamp',
        converter: TypedDataHelpers.dateTimeConverter,
      );

  @override
  MutableScore toMutable() => MutableScore.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'Score',
        fields: {
          'id': id,
          'title': title,
          'composers': composers,
          'lyricists': lyricists,
          'instruments': instruments,
          'isFavourite': isFavourite,
          'lastChangeTimestamp': lastChangeTimestamp,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableScore extends _ScoreImplBase {
  ImmutableScore.internal(super.internal);

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

  static const _instrumentsConverter = const TypedListConverter(
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
  late final instruments = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'instruments',
    key: 'instruments',
    converter: _instrumentsConverter,
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
    required String title,
    required List<String> composers,
    required List<String> lyricists,
    required List<String> instruments,
    required bool isFavourite,
    required DateTime lastChangeTimestamp,
  }) : super(MutableDocument.withId(id)) {
    this.title = title;
    this.composers = composers;
    this.lyricists = lyricists;
    this.instruments = instruments;
    this.isFavourite = isFavourite;
    this.lastChangeTimestamp = lastChangeTimestamp;
  }

  MutableScore.internal(super.internal);

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

  static const _instrumentsConverter = const TypedListConverter(
    converter: TypedDataHelpers.stringConverter,
    isNullable: false,
    isCached: false,
  );

  set title(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'title',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

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

  set isFavourite(bool value) {
    final promoted = TypedDataHelpers.boolConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'isFavourite',
      value: promoted,
      converter: TypedDataHelpers.boolConverter,
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
}

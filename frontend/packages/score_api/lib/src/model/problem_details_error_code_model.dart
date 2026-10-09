// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i3;
import 'dart:core' as _i2;

import 'package:tonik_util/tonik_util.dart' as _i1;

/// A code on which an application can act. This is a machine readable code,
/// not meant to display to an end-user, but can be used to show a translated
/// error message.
///
/// It is what a caller should branch on. `status` says how the request
/// failed in the terms http has, and `detail` says it in the terms a
/// developer reading a log has; neither is stable enough to switch on. This
/// is: the set below only ever grows, and a code is never given a new
/// meaning.
///
///
/// **Example**:
/// ```
/// score_not_found
/// ```
enum ProblemDetailsErrorCodeModel
    implements
        _i1.MatrixEncodable,
        _i1.LabelEncodable,
        _i1.SimpleEncodable,
        _i1.FormEncodable,
        _i1.JsonEncodable,
        _i1.UriEncodable {
  invalidRequest(r'invalid_request'),
  invalidMusicXml(r'invalid_music_xml'),
  invalidCredentials(r'invalid_credentials'),
  missingRole(r'missing_role'),
  scoreNotFound(r'score_not_found'),
  setNotFound(r'set_not_found'),
  setEntryNotFound(r'set_entry_not_found'),
  invalidSet(r'invalid_set'),
  invalidSetEntry(r'invalid_set_entry'),
  unknownScore(r'unknown_score'),
  notSetOwner(r'not_set_owner'),
  collectionNotFound(r'collection_not_found'),
  collectionEntryNotFound(r'collection_entry_not_found'),
  invalidCollection(r'invalid_collection'),
  invalidCollectionEntry(r'invalid_collection_entry'),
  notCollectionOwner(r'not_collection_owner'),
  scoreAlreadyInCollection(r'score_already_in_collection'),
  endpointNotFound(r'endpoint_not_found'),
  methodNotAllowed(r'method_not_allowed'),
  unsupportedMediaType(r'unsupported_media_type'),
  requestBodyTooLarge(r'request_body_too_large'),
  internalError(r'internal_error');

  const ProblemDetailsErrorCodeModel(this._$rawValue);

  factory ProblemDetailsErrorCodeModel.fromJson(_i2.dynamic value) {
    if (value is! _i2.String) {
      throw _i1.JsonDecodingException(
        r'Expected String for ProblemDetailsErrorCodeModel, got ${value.runtimeType}',
      );
    }
    return values.firstWhere(
      (e) => e._$rawValue == value,
      orElse: () => throw _i1.JsonDecodingException(
        r'No matching ProblemDetailsErrorCodeModel for value: $value',
      ),
    );
  }

  factory ProblemDetailsErrorCodeModel.fromSimple(
    _i2.String? value, {
    required _i2.bool explode,
    _i2.String? context,
  }) {
    return ProblemDetailsErrorCodeModel.fromJson(
      value.decodeSimpleString(context: context),
    );
  }

  factory ProblemDetailsErrorCodeModel.fromForm(
    _i2.String? value, {
    required _i2.bool explode,
    _i2.String? context,
  }) {
    return ProblemDetailsErrorCodeModel.fromJson(
      value.decodeFormString(context: context),
    );
  }

  final _i2.String _$rawValue;

  @_i2.override
  _i2.String toJson() => _$rawValue;

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.simple;

  @_i2.override
  _i2.String toSimple({
    required _i2.bool explode,
    required _i2.bool allowEmpty,
    _i2.bool literal = false,
  }) => _$rawValue.toSimple(
    explode: explode,
    allowEmpty: allowEmpty,
    literal: literal,
  );

  @_i2.override
  _i2.List<_i1.ParameterEntry> toForm(
    _i2.String paramName, {
    required _i2.bool explode,
    required _i2.bool allowEmpty,
    required _i3.Encoding textEncoding,
    _i2.bool useQueryComponent = false,
    _i2.bool allowReserved = false,
    _i2.Map<_i2.String, _i1.FormFieldEncoding> fieldEncodings = const {},
  }) => _$rawValue.toForm(
    paramName,
    explode: explode,
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: allowReserved,
    textEncoding: textEncoding,
  );

  @_i2.override
  _i2.String toLabel({
    required _i2.bool explode,
    required _i2.bool allowEmpty,
  }) => _$rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);

  @_i2.override
  _i2.String uriEncode({
    required _i2.bool allowEmpty,
    required _i3.Encoding textEncoding,
    _i2.bool useQueryComponent = false,
    _i2.bool allowReserved = false,
  }) => _$rawValue.uriEncode(
    allowEmpty: allowEmpty,
    textEncoding: textEncoding,
    useQueryComponent: useQueryComponent,
    allowReserved: allowReserved,
  );

  @_i2.override
  _i2.String toMatrix(
    _i2.String paramName, {
    required _i2.bool explode,
    required _i2.bool allowEmpty,
  }) =>
      _$rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
}

// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i6;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/deleted_resource.dart' as _i4;
import 'package:score_api/src/model/set.dart' as _i5;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A set as the change window lists it: whole while it exists, and as nothing
/// but its id and when it was deleted once it is gone.
///
@_i2.immutable
sealed class ListedSet implements _i1.ParameterEncodable, _i1.UriEncodable {
  const ListedSet();

  factory ListedSet.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    try {
      return ListedSetDeletedResource(
        _i4.DeletedResource.fromSimple(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    try {
      return ListedSetSet(_i5.Set.fromSimple(value, explode: explode));
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    throw _i1.SimpleDecodingException(r'Invalid simple value for ListedSet');
  }

  factory ListedSet.fromForm(_i3.String? value, {required _i3.bool explode}) {
    try {
      return ListedSetDeletedResource(
        _i4.DeletedResource.fromForm(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    try {
      return ListedSetSet(_i5.Set.fromForm(value, explode: explode));
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    throw _i1.SimpleDecodingException(r'Invalid form value for ListedSet');
  }

  factory ListedSet.fromJson(_i3.Object? json) {
    try {
      return ListedSetDeletedResource(_i4.DeletedResource.fromJson(json));
    } on _i3.Object catch (_) {}
    try {
      return ListedSetSet(_i5.Set.fromJson(json));
    } on _i3.Object catch (_) {}
    throw _i1.JsonDecodingException(r'Invalid JSON for ListedSet');
  }

  _i1.EncodingShape get currentEncodingShape {
    return switch (this) {
      ListedSetSet(:final value) => value.currentEncodingShape,
      ListedSetDeletedResource(:final value) => value.currentEncodingShape,
    };
  }

  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    return switch (this) {
      ListedSetSet(:final value) => value.parameterProperties(
        allowEmpty: allowEmpty,
      ),
      ListedSetDeletedResource(:final value) => value.parameterProperties(
        allowEmpty: allowEmpty,
      ),
    };
  }

  @_i3.override
  _i3.String toSimple({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
    _i3.bool literal = false,
  }) {
    return switch (this) {
      ListedSetSet(:final value) => value.toSimple(
        explode: explode,
        allowEmpty: allowEmpty,
        literal: literal,
      ),
      ListedSetDeletedResource(:final value) => value.toSimple(
        explode: explode,
        allowEmpty: allowEmpty,
        literal: literal,
      ),
    };
  }

  @_i3.override
  _i3.List<_i1.ParameterEntry> toForm(
    _i3.String paramName, {
    required _i3.bool explode,
    required _i3.bool allowEmpty,
    required _i6.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
    _i3.Map<_i3.String, _i1.FormFieldEncoding> fieldEncodings = const {},
  }) {
    return switch (this) {
      ListedSetSet(:final value) => value.toForm(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
        textEncoding: textEncoding,
      ),
      ListedSetDeletedResource(:final value) => value.toForm(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
        textEncoding: textEncoding,
      ),
    };
  }

  @_i3.override
  _i3.String toLabel({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return switch (this) {
      ListedSetSet(:final value) => value.toLabel(
        explode: explode,
        allowEmpty: allowEmpty,
      ),
      ListedSetDeletedResource(:final value) => value.toLabel(
        explode: explode,
        allowEmpty: allowEmpty,
      ),
    };
  }

  @_i3.override
  _i3.String toMatrix(
    _i3.String paramName, {
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return switch (this) {
      ListedSetSet(:final value) => value.toMatrix(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
      ),
      ListedSetDeletedResource(:final value) => value.toMatrix(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
      ),
    };
  }

  @_i3.override
  _i3.List<_i1.ParameterEntry> toDeepObject(
    _i3.String paramName, {
    required _i3.bool explode,
    required _i3.bool allowEmpty,
    _i3.bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  @_i3.override
  _i3.List<_i1.ParameterEntry> toPipeDelimited(
    _i3.String paramName, {
    required _i3.bool allowEmpty,
    _i3.bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toPipeDelimited(
      paramName,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  @_i3.override
  _i3.List<_i1.ParameterEntry> toSpaceDelimited(
    _i3.String paramName, {
    required _i3.bool allowEmpty,
    _i3.bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toSpaceDelimited(
      paramName,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i6.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    return switch (this) {
      ListedSetSet() => throw _i1.EncodingException(
        r'Cannot uriEncode ListedSet: variant contains complex type',
      ),
      ListedSetDeletedResource() => throw _i1.EncodingException(
        r'Cannot uriEncode ListedSet: variant contains complex type',
      ),
    };
  }

  @_i3.override
  _i3.Object? toJson() {
    final (_i3.dynamic _$json, _i3.String? _$discriminator) = switch (this) {
      ListedSetSet(:final value) => (value.toJson(), null),

      ListedSetDeletedResource(:final value) => (value.toJson(), null),
    };
    return _$json;
  }
}

@_i2.immutable
class ListedSetSet extends ListedSet {
  const ListedSetSet(this.value);

  final _i5.Set value;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListedSetSet && other.value == this.value;
  }

  @_i3.override
  _i3.int get hashCode => value.hashCode;
}

@_i2.immutable
class ListedSetDeletedResource extends ListedSet {
  const ListedSetDeletedResource(this.value);

  final _i4.DeletedResource value;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListedSetDeletedResource && other.value == this.value;
  }

  @_i3.override
  _i3.int get hashCode => value.hashCode;
}

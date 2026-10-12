// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i6;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/collection.dart' as _i4;
import 'package:score_api/src/model/deleted_resource.dart' as _i5;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A collection as the change window lists it: whole while it exists, and as nothing
/// but its id and when it was deleted once it is gone.
///
@_i2.immutable
sealed class ListedCollection
    implements _i1.ParameterEncodable, _i1.UriEncodable {
  const ListedCollection();

  factory ListedCollection.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    try {
      return ListedCollectionCollection(
        _i4.Collection.fromSimple(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    try {
      return ListedCollectionDeletedResource(
        _i5.DeletedResource.fromSimple(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    throw _i1.SimpleDecodingException(
      r'Invalid simple value for ListedCollection',
    );
  }

  factory ListedCollection.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    try {
      return ListedCollectionCollection(
        _i4.Collection.fromForm(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    try {
      return ListedCollectionDeletedResource(
        _i5.DeletedResource.fromForm(value, explode: explode),
      );
    } on _i1.DecodingException catch (_) {
    } on _i3.FormatException catch (_) {}
    throw _i1.SimpleDecodingException(
      r'Invalid form value for ListedCollection',
    );
  }

  factory ListedCollection.fromJson(_i3.Object? json) {
    try {
      return ListedCollectionCollection(_i4.Collection.fromJson(json));
    } on _i3.Object catch (_) {}
    try {
      return ListedCollectionDeletedResource(
        _i5.DeletedResource.fromJson(json),
      );
    } on _i3.Object catch (_) {}
    throw _i1.JsonDecodingException(r'Invalid JSON for ListedCollection');
  }

  _i1.EncodingShape get currentEncodingShape {
    return switch (this) {
      ListedCollectionCollection(:final value) => value.currentEncodingShape,
      ListedCollectionDeletedResource(:final value) =>
        value.currentEncodingShape,
    };
  }

  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    return switch (this) {
      ListedCollectionCollection(:final value) => value.parameterProperties(
        allowEmpty: allowEmpty,
      ),
      ListedCollectionDeletedResource(:final value) =>
        value.parameterProperties(allowEmpty: allowEmpty),
    };
  }

  @_i3.override
  _i3.String toSimple({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
    _i3.bool literal = false,
  }) {
    return switch (this) {
      ListedCollectionCollection(:final value) => value.toSimple(
        explode: explode,
        allowEmpty: allowEmpty,
        literal: literal,
      ),
      ListedCollectionDeletedResource(:final value) => value.toSimple(
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
      ListedCollectionCollection(:final value) => value.toForm(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
        textEncoding: textEncoding,
      ),
      ListedCollectionDeletedResource(:final value) => value.toForm(
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
      ListedCollectionCollection(:final value) => value.toLabel(
        explode: explode,
        allowEmpty: allowEmpty,
      ),
      ListedCollectionDeletedResource(:final value) => value.toLabel(
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
      ListedCollectionCollection(:final value) => value.toMatrix(
        paramName,
        explode: explode,
        allowEmpty: allowEmpty,
      ),
      ListedCollectionDeletedResource(:final value) => value.toMatrix(
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
      ListedCollectionCollection() => throw _i1.EncodingException(
        r'Cannot uriEncode ListedCollection: variant contains complex type',
      ),
      ListedCollectionDeletedResource() => throw _i1.EncodingException(
        r'Cannot uriEncode ListedCollection: variant contains complex type',
      ),
    };
  }

  @_i3.override
  _i3.Object? toJson() {
    final (_i3.dynamic _$json, _i3.String? _$discriminator) = switch (this) {
      ListedCollectionCollection(:final value) => (value.toJson(), null),

      ListedCollectionDeletedResource(:final value) => (value.toJson(), null),
    };
    return _$json;
  }
}

@_i2.immutable
class ListedCollectionCollection extends ListedCollection {
  const ListedCollectionCollection(this.value);

  final _i4.Collection value;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListedCollectionCollection && other.value == this.value;
  }

  @_i3.override
  _i3.int get hashCode => value.hashCode;
}

@_i2.immutable
class ListedCollectionDeletedResource extends ListedCollection {
  const ListedCollectionDeletedResource(this.value);

  final _i5.DeletedResource value;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListedCollectionDeletedResource &&
        other.value == this.value;
  }

  @_i3.override
  _i3.int get hashCode => value.hashCode;
}

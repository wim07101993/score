// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i6;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i5;
import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/set_entry.dart' as _i4;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A playlist for a gig: an ordered list of scores, each with the key it is
/// played in and the parts that are on screen.
///
/// A set says how a score is played, never what it is. Nothing in it changes a
/// score, and two sets can play the same score in different keys without either
/// of them changing it.
///
@_i2.immutable
class Set extends _i1.ObjectParameterEncodable implements _i1.UriEncodable {
  const Set({
    required this.id,
    required this.title,
    required this.description,
    required this.entries,
    required this.sharedWith,
    required this.isOwner,
    required this.lastChangedAt,
  });

  factory Set.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for Set: contains complex types',
    );
  }

  factory Set.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'Set');
    return Set(
      id: _$map[r'id'].decodeJsonString(context: r'Set.id'),
      title: _$map[r'title'].decodeJsonString(context: r'Set.title'),
      description: _$map[r'description'].decodeJsonString(
        context: r'Set.description',
      ),
      entries: _$map[r'entries']
          .decodeJsonList<_i3.Object?>(context: r'Set.entries')
          .map(_i4.SetEntry.fromJson)
          .toList(),
      sharedWith: _$map[r'shared_with'].decodeJsonList<_i3.String>(
        context: r'Set.shared_with',
      ),
      isOwner: _$map[r'is_owner'].decodeJsonBool(context: r'Set.is_owner'),
      lastChangedAt: _$map[r'last_changed_at'].decodeJsonDateTime(
        context: r'Set.last_changed_at',
      ),
    );
  }

  factory Set.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for Set: contains complex types',
    );
  }

  /// The id the set was stored under.
  final _i3.String id;

  /// **Example**:
  /// ```
  /// Zomerbar 12 juli
  /// ```
  final _i3.String title;

  /// Whatever the player needs to remember about the gig as a whole.
  final _i3.String description;

  /// The scores that are played, in playing order.
  final _i3.List<_i4.SetEntry> entries;

  /// The addresses the set is readable by.
  ///
  /// Only filled in for the owner; for everyone else it is empty. Who else
  /// someone shares with is not the business of the people they share with.
  ///
  ///
  /// **Example**:
  /// ```json
  /// [
  ///   "bas@example.com"
  /// ]
  /// ```
  final _i3.List<_i3.String> sharedWith;

  /// Whether this set is the caller's to change. A set that is only shared
  /// with the caller can be read but not written or deleted.
  ///
  final _i3.bool isOwner;

  /// When the set was last written.
  final _i3.DateTime lastChangedAt;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'title': title,
    r'description': description,
    r'entries': entries.map((e) => e.toJson()).toList(),
    r'shared_with': sharedWith,
    r'is_owner': isOwner,
    r'last_changed_at': lastChangedAt.toTimeZonedIso8601String(),
  };

  $$SetCopyWith<Set> get copyWith => _SetCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i5.DeepCollectionEquality();
    return other is Set &&
        other.id == this.id &&
        other.title == this.title &&
        other.description == this.description &&
        _$deepEquals.equals(other.entries, this.entries) &&
        _$deepEquals.equals(other.sharedWith, this.sharedWith) &&
        other.isOwner == this.isOwner &&
        other.lastChangedAt == this.lastChangedAt;
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i5.DeepCollectionEquality();
    return _i3.Object.hashAll([
      id,
      title,
      description,
      deepEquals.hash(entries),
      deepEquals.hash(sharedWith),
      isOwner,
      lastChangedAt,
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for Set: contains complex types',
  );

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i6.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode Set: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$SetCopyWith<$Res> {
  factory $$SetCopyWith(Set value) = _SetCopyWith<$Res>;

  $Res call({
    _i3.String? id,
    _i3.String? title,
    _i3.String? description,
    _i3.List<_i4.SetEntry>? entries,
    _i3.List<_i3.String>? sharedWith,
    _i3.bool? isOwner,
    _i3.DateTime? lastChangedAt,
  });
  _i3.String get id;
  _i3.String get title;
  _i3.String get description;
  _i3.List<_i4.SetEntry> get entries;
  _i3.List<_i3.String> get sharedWith;
  _i3.bool get isOwner;
  _i3.DateTime get lastChangedAt;
}

class _SetCopyWith<$Res> implements $$SetCopyWith<$Res> {
  _SetCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final Set _value;

  @_i3.override
  _i3.String get id => _value.id;

  @_i3.override
  _i3.String get title => _value.title;

  @_i3.override
  _i3.String get description => _value.description;

  @_i3.override
  _i3.List<_i4.SetEntry> get entries => _value.entries;

  @_i3.override
  _i3.List<_i3.String> get sharedWith => _value.sharedWith;

  @_i3.override
  _i3.bool get isOwner => _value.isOwner;

  @_i3.override
  _i3.DateTime get lastChangedAt => _value.lastChangedAt;

  @_i3.override
  $Res call({
    _i3.Object? id = _sentinel,
    _i3.Object? title = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? entries = _sentinel,
    _i3.Object? sharedWith = _sentinel,
    _i3.Object? isOwner = _sentinel,
    _i3.Object? lastChangedAt = _sentinel,
  }) {
    return (Set(
      id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.String),
      title: _i3.identical(title, _sentinel)
          ? this.title
          : (title as _i3.String),
      description: _i3.identical(description, _sentinel)
          ? this.description
          : (description as _i3.String),
      entries: _i3.identical(entries, _sentinel)
          ? this.entries
          : (entries as _i3.List<_i4.SetEntry>),
      sharedWith: _i3.identical(sharedWith, _sentinel)
          ? this.sharedWith
          : (sharedWith as _i3.List<_i3.String>),
      isOwner: _i3.identical(isOwner, _sentinel)
          ? this.isOwner
          : (isOwner as _i3.bool),
      lastChangedAt: _i3.identical(lastChangedAt, _sentinel)
          ? this.lastChangedAt
          : (lastChangedAt as _i3.DateTime),
    ) as $Res);
  }
}

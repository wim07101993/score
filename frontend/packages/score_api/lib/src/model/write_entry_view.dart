// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A view as the player states it, of one entry of a set or a collection. It is
/// the read view whole: there is nothing about a view the server decides, and a
/// write replaces it rather than adding to it.
///
@_i2.immutable
class WriteEntryView extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const WriteEntryView({
    required this.transposition,
    required this.hiddenParts,
    this.zoom = zoomDefault,
  });

  factory WriteEntryView.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'transposition', r'hidden_parts', r'zoom'},
      listKeys: {r'hidden_parts'},
      context: r'WriteEntryView',
    );
    return WriteEntryView(
      transposition: _$values[r'transposition'].decodeSimpleInt(
        context: r'WriteEntryView.transposition',
      ),
      hiddenParts: _$values[r'hidden_parts'].decodeSimpleStringList(
        context: r'WriteEntryView.hidden_parts',
      ),
      zoom: _$values.containsKey(r'zoom')
          ? _$values[r'zoom'].decodeSimpleDouble(
              context: r'WriteEntryView.zoom',
            )
          : zoomDefault,
    );
  }

  factory WriteEntryView.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'WriteEntryView');
    return WriteEntryView(
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'WriteEntryView.transposition',
      ),
      hiddenParts: _$map[r'hidden_parts'].decodeJsonList<_i3.String>(
        context: r'WriteEntryView.hidden_parts',
      ),
      zoom: _$map.containsKey(r'zoom')
          ? _$map[r'zoom'].decodeJsonDouble(context: r'WriteEntryView.zoom')
          : zoomDefault,
    );
  }

  factory WriteEntryView.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'transposition', r'hidden_parts', r'zoom'},
      listKeys: {r'hidden_parts'},
      context: r'WriteEntryView',
    );
    return WriteEntryView(
      transposition: _$values[r'transposition'].decodeFormInt(
        context: r'WriteEntryView.transposition',
      ),
      hiddenParts: _$values[r'hidden_parts'].decodeFormStringList(
        context: r'WriteEntryView.hidden_parts',
      ),
      zoom: _$values.containsKey(r'zoom')
          ? _$values[r'zoom'].decodeFormDouble(context: r'WriteEntryView.zoom')
          : zoomDefault,
    );
  }

  static const _i3.double zoomDefault = 1.0;

  /// How far this player reads the score from where the others play it, in
  /// semitones, negative for down.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 9
  /// ```
  final _i3.int transposition;

  /// The parts of the score this player has off screen, by their MusicXML part
  /// id. They are replaced rather than merged: this is the whole of the list.
  ///
  ///
  /// **Example**:
  /// ```json
  /// [
  ///   "P2",
  ///   "P3"
  /// ]
  /// ```
  final _i3.List<_i3.String> hiddenParts;

  /// How big this player draws the score, where 1 is the size it is written
  /// at.
  ///
  /// It is not required, and a body that leaves it out is read as the size the
  /// score is written at. A client that was written before there was such a
  /// thing as a size is still saying something true about the key and the
  /// parts, and refusing what it queued up over a field it has never heard of
  /// would throw that away.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 1.5
  /// ```
  final _i3.double? zoom;

  @_i3.override
  _i3.Object? toJson() => {
    r'transposition': transposition,
    r'hidden_parts': hiddenParts,
    if (zoom != null) r'zoom': zoom,
  };

  $$WriteEntryViewCopyWith<WriteEntryView> get copyWith =>
      _WriteEntryViewCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i4.DeepCollectionEquality();
    return other is WriteEntryView &&
        other.transposition == this.transposition &&
        _$deepEquals.equals(other.hiddenParts, this.hiddenParts) &&
        other.zoom == this.zoom;
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i4.DeepCollectionEquality();
    return _i3.Object.hashAll([
      transposition,
      deepEquals.hash(hiddenParts),
      zoom,
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'transposition'] = _i1.PropertyValue.scalar(
      transposition.toString(),
    );
    _$result[r'hidden_parts'] = _i1.PropertyValue.array(hiddenParts);
    if (zoom != null) {
      _$result[r'zoom'] = _i1.PropertyValue.scalar(zoom!.toString());
    }
    return _$result;
  }

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i5.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode WriteEntryView: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$WriteEntryViewCopyWith<$Res> {
  factory $$WriteEntryViewCopyWith(WriteEntryView value) =
      _WriteEntryViewCopyWith<$Res>;

  $Res call({
    _i3.int? transposition,
    _i3.List<_i3.String>? hiddenParts,
    _i3.double? zoom,
  });
  _i3.int get transposition;
  _i3.List<_i3.String> get hiddenParts;
  _i3.double? get zoom;
}

class _WriteEntryViewCopyWith<$Res> implements $$WriteEntryViewCopyWith<$Res> {
  _WriteEntryViewCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final WriteEntryView _value;

  @_i3.override
  _i3.int get transposition => _value.transposition;

  @_i3.override
  _i3.List<_i3.String> get hiddenParts => _value.hiddenParts;

  @_i3.override
  _i3.double? get zoom => _value.zoom;

  @_i3.override
  $Res call({
    _i3.Object? transposition = _sentinel,
    _i3.Object? hiddenParts = _sentinel,
    _i3.Object? zoom = _sentinel,
  }) {
    return (WriteEntryView(
      transposition: _i3.identical(transposition, _sentinel)
          ? this.transposition
          : (transposition as _i3.int),
      hiddenParts: _i3.identical(hiddenParts, _sentinel)
          ? this.hiddenParts
          : (hiddenParts as _i3.List<_i3.String>),
      zoom: _i3.identical(zoom, _sentinel) ? this.zoom : (zoom as _i3.double?),
    ) as $Res);
  }
}

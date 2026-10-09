// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// How one player looks at one entry of a set or a collection.
///
/// A set says what the band plays and a collection says what the group has;
/// a view says what one player looks at while they play it. The two are kept
/// apart because they are not the same decision: playing a song a tone down is
/// the band's, and reading it in another key because of the instrument it is
/// played on is the player's own. A saxophone player transposing their part
/// changes nothing for the pianist, and the pianist wanting the piano staff alone
/// on screen changes nothing for the singer.
///
/// It is the same thing in both, because it is the same music being read by the
/// same player: a piece read a fourth up off a tablet at arm's length is read
/// that way whether it was opened out of a gig or out of a book. What it belongs
/// to is the entry, so a piece that is in a set and in a collection is two
/// entries and two views — the band's arrangement of it and the book's are two
/// different things to read.
///
/// A view belongs to whoever asked for the set or collection. Everyone it is
/// shared with has their own, everyone can write their own without being the
/// owner, and nobody is told anything about anybody else's.
///
/// An entry that a player has never looked at differently has the view every
/// entry starts with: as written, every part on screen.
///
@_i2.immutable
class EntryView extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const EntryView({
    required this.transposition,
    required this.hiddenParts,
    this.zoom = zoomDefault,
  });

  factory EntryView.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'transposition', r'hidden_parts', r'zoom'},
      listKeys: {r'hidden_parts'},
      context: r'EntryView',
    );
    return EntryView(
      transposition: _$values[r'transposition'].decodeSimpleInt(
        context: r'EntryView.transposition',
      ),
      hiddenParts: _$values[r'hidden_parts'].decodeSimpleStringList(
        context: r'EntryView.hidden_parts',
      ),
      zoom: _$values.containsKey(r'zoom')
          ? _$values[r'zoom'].decodeSimpleDouble(context: r'EntryView.zoom')
          : zoomDefault,
    );
  }

  factory EntryView.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'EntryView');
    return EntryView(
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'EntryView.transposition',
      ),
      hiddenParts: _$map[r'hidden_parts'].decodeJsonList<_i3.String>(
        context: r'EntryView.hidden_parts',
      ),
      zoom: _$map.containsKey(r'zoom')
          ? _$map[r'zoom'].decodeJsonDouble(context: r'EntryView.zoom')
          : zoomDefault,
    );
  }

  factory EntryView.fromForm(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'transposition', r'hidden_parts', r'zoom'},
      listKeys: {r'hidden_parts'},
      context: r'EntryView',
    );
    return EntryView(
      transposition: _$values[r'transposition'].decodeFormInt(
        context: r'EntryView.transposition',
      ),
      hiddenParts: _$values[r'hidden_parts'].decodeFormStringList(
        context: r'EntryView.hidden_parts',
      ),
      zoom: _$values.containsKey(r'zoom')
          ? _$values[r'zoom'].decodeFormDouble(context: r'EntryView.zoom')
          : zoomDefault,
    );
  }

  static const _i3.double zoomDefault = 1.0;

  /// How far this player reads the score from where the others play it, in
  /// semitones, negative for down.
  ///
  /// It is on top of the entry's own transposition rather than instead of it:
  /// the entry says this one is played a tone down, and this says the player
  /// reads that a fifth up. What ends up on screen is the two together, brought
  /// back inside the octave either way that the player offers when they add up
  /// past it.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 9
  /// ```
  final _i3.int transposition;

  /// The parts of the score this player has off screen, by their MusicXML part
  /// id.
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
  /// It belongs with the key they read it in and the parts they have on
  /// screen, for the same reason those do: it is about the player and the
  /// screen they read from rather than about the music. The one reading at
  /// arm's length off a tablet on a stand and the one holding a phone are two
  /// answers to the same question, and neither is the score's.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 1.5
  /// ```
  final _i3.double zoom;

  @_i3.override
  _i3.Object? toJson() => {
    r'transposition': transposition,
    r'hidden_parts': hiddenParts,
    r'zoom': zoom,
  };

  $$EntryViewCopyWith<EntryView> get copyWith => _EntryViewCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i4.DeepCollectionEquality();
    return other is EntryView &&
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
    _$result[r'zoom'] = _i1.PropertyValue.scalar(zoom.toString());
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
      r'Cannot uriEncode EntryView: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$EntryViewCopyWith<$Res> {
  factory $$EntryViewCopyWith(EntryView value) = _EntryViewCopyWith<$Res>;

  $Res call({
    _i3.int? transposition,
    _i3.List<_i3.String>? hiddenParts,
    _i3.double? zoom,
  });
  _i3.int get transposition;
  _i3.List<_i3.String> get hiddenParts;
  _i3.double get zoom;
}

class _EntryViewCopyWith<$Res> implements $$EntryViewCopyWith<$Res> {
  _EntryViewCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final EntryView _value;

  @_i3.override
  _i3.int get transposition => _value.transposition;

  @_i3.override
  _i3.List<_i3.String> get hiddenParts => _value.hiddenParts;

  @_i3.override
  _i3.double get zoom => _value.zoom;

  @_i3.override
  $Res call({
    _i3.Object? transposition = _sentinel,
    _i3.Object? hiddenParts = _sentinel,
    _i3.Object? zoom = _sentinel,
  }) {
    return (EntryView(
      transposition: _i3.identical(transposition, _sentinel)
          ? this.transposition
          : (transposition as _i3.int),
      hiddenParts: _i3.identical(hiddenParts, _sentinel)
          ? this.hiddenParts
          : (hiddenParts as _i3.List<_i3.String>),
      zoom: _i3.identical(zoom, _sentinel) ? this.zoom : (zoom as _i3.double),
    ) as $Res);
  }
}

// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;

@_i1.immutable
sealed class ScoresScoreIdPutBodyRequestBody {
  const ScoresScoreIdPutBodyRequestBody();
}

@_i1.immutable
class ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml
    extends ScoresScoreIdPutBodyRequestBody {
  const ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml(this.value);

  final _i2.String value;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml &&
        other.value == this.value;
  }

  @_i2.override
  _i2.int get hashCode => value.hashCode;
}

@_i1.immutable
class ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxmlXml
    extends ScoresScoreIdPutBodyRequestBody {
  const ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxmlXml(this.value);

  final _i2.String value;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxmlXml &&
        other.value == this.value;
  }

  @_i2.override
  _i2.int get hashCode => value.hashCode;
}

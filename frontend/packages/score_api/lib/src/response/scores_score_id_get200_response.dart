// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/score.dart' as _i2;

@_i1.immutable
sealed class ScoresScoreIdGet200Response {
  const ScoresScoreIdGet200Response();
}

@_i1.immutable
class ScoresScoreIdGet200ResponseJson extends ScoresScoreIdGet200Response {
  const ScoresScoreIdGet200ResponseJson({required this.body});

  final _i2.Score body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ScoresScoreIdGet200ResponseJson && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ScoresScoreIdGet200ResponseVndRecordareMusicxml
    extends ScoresScoreIdGet200Response {
  const ScoresScoreIdGet200ResponseVndRecordareMusicxml({required this.body});

  final _i3.String body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ScoresScoreIdGet200ResponseVndRecordareMusicxml &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ScoresScoreIdGet200ResponseVndRecordareMusicxmlXml
    extends ScoresScoreIdGet200Response {
  const ScoresScoreIdGet200ResponseVndRecordareMusicxmlXml({
    required this.body,
  });

  final _i3.String body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ScoresScoreIdGet200ResponseVndRecordareMusicxmlXml &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

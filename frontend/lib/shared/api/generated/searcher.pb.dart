//
//  Generated code. Do not modify.
//  source: searcher.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $3;

class GetScoresRequest extends $pb.GeneratedMessage {
  factory GetScoresRequest({
    $3.Timestamp? changedSince,
    $core.bool? onlyFavourites,
  }) {
    final $result = create();
    if (changedSince != null) {
      $result.changedSince = changedSince;
    }
    if (onlyFavourites != null) {
      $result.onlyFavourites = onlyFavourites;
    }
    return $result;
  }
  GetScoresRequest._() : super();
  factory GetScoresRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetScoresRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetScoresRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOM<$3.Timestamp>(1, _omitFieldNames ? '' : 'changedSince', subBuilder: $3.Timestamp.create)
    ..aOB(2, _omitFieldNames ? '' : 'onlyFavourites')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetScoresRequest clone() => GetScoresRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetScoresRequest copyWith(void Function(GetScoresRequest) updates) => super.copyWith((message) => updates(message as GetScoresRequest)) as GetScoresRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetScoresRequest create() => GetScoresRequest._();
  GetScoresRequest createEmptyInstance() => create();
  static $pb.PbList<GetScoresRequest> createRepeated() => $pb.PbList<GetScoresRequest>();
  @$core.pragma('dart2js:noInline')
  static GetScoresRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetScoresRequest>(create);
  static GetScoresRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $3.Timestamp get changedSince => $_getN(0);
  @$pb.TagNumber(1)
  set changedSince($3.Timestamp v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChangedSince() => $_has(0);
  @$pb.TagNumber(1)
  void clearChangedSince() => clearField(1);
  @$pb.TagNumber(1)
  $3.Timestamp ensureChangedSince() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get onlyFavourites => $_getBF(1);
  @$pb.TagNumber(2)
  set onlyFavourites($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOnlyFavourites() => $_has(1);
  @$pb.TagNumber(2)
  void clearOnlyFavourites() => clearField(2);
}

class ScoresPage extends $pb.GeneratedMessage {
  factory ScoresPage({
    $fixnum.Int64? totalHits,
    $core.Iterable<Score>? scores,
  }) {
    final $result = create();
    if (totalHits != null) {
      $result.totalHits = totalHits;
    }
    if (scores != null) {
      $result.scores.addAll(scores);
    }
    return $result;
  }
  ScoresPage._() : super();
  factory ScoresPage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ScoresPage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ScoresPage', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'totalHits')
    ..pc<Score>(2, _omitFieldNames ? '' : 'scores', $pb.PbFieldType.PM, subBuilder: Score.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ScoresPage clone() => ScoresPage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ScoresPage copyWith(void Function(ScoresPage) updates) => super.copyWith((message) => updates(message as ScoresPage)) as ScoresPage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScoresPage create() => ScoresPage._();
  ScoresPage createEmptyInstance() => create();
  static $pb.PbList<ScoresPage> createRepeated() => $pb.PbList<ScoresPage>();
  @$core.pragma('dart2js:noInline')
  static ScoresPage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScoresPage>(create);
  static ScoresPage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get totalHits => $_getI64(0);
  @$pb.TagNumber(1)
  set totalHits($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTotalHits() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalHits() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Score> get scores => $_getList(1);
}

class Score extends $pb.GeneratedMessage {
  factory Score({
    $core.String? id,
    $core.String? title,
    $core.Iterable<$core.String>? composers,
    $core.Iterable<$core.String>? lyricists,
    $core.Iterable<$core.String>? instruments,
    $core.bool? isFavourite,
    $3.Timestamp? lastChangeTimestamp,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (title != null) {
      $result.title = title;
    }
    if (composers != null) {
      $result.composers.addAll(composers);
    }
    if (lyricists != null) {
      $result.lyricists.addAll(lyricists);
    }
    if (instruments != null) {
      $result.instruments.addAll(instruments);
    }
    if (isFavourite != null) {
      $result.isFavourite = isFavourite;
    }
    if (lastChangeTimestamp != null) {
      $result.lastChangeTimestamp = lastChangeTimestamp;
    }
    return $result;
  }
  Score._() : super();
  factory Score.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Score.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Score', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..pPS(3, _omitFieldNames ? '' : 'composers')
    ..pPS(4, _omitFieldNames ? '' : 'lyricists')
    ..pPS(5, _omitFieldNames ? '' : 'instruments')
    ..aOB(6, _omitFieldNames ? '' : 'isFavourite', protoName: 'isFavourite')
    ..aOM<$3.Timestamp>(7, _omitFieldNames ? '' : 'lastChangeTimestamp', subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Score clone() => Score()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Score copyWith(void Function(Score) updates) => super.copyWith((message) => updates(message as Score)) as Score;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Score create() => Score._();
  Score createEmptyInstance() => create();
  static $pb.PbList<Score> createRepeated() => $pb.PbList<Score>();
  @$core.pragma('dart2js:noInline')
  static Score getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Score>(create);
  static Score? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get composers => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get lyricists => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$core.String> get instruments => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get isFavourite => $_getBF(5);
  @$pb.TagNumber(6)
  set isFavourite($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsFavourite() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsFavourite() => clearField(6);

  @$pb.TagNumber(7)
  $3.Timestamp get lastChangeTimestamp => $_getN(6);
  @$pb.TagNumber(7)
  set lastChangeTimestamp($3.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasLastChangeTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastChangeTimestamp() => clearField(7);
  @$pb.TagNumber(7)
  $3.Timestamp ensureLastChangeTimestamp() => $_ensure(6);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

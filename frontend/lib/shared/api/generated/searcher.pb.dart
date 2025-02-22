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

class GetScoreRequest extends $pb.GeneratedMessage {
  factory GetScoreRequest({
    $core.String? scoreId,
  }) {
    final $result = create();
    if (scoreId != null) {
      $result.scoreId = scoreId;
    }
    return $result;
  }
  GetScoreRequest._() : super();
  factory GetScoreRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetScoreRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetScoreRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'scoreId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetScoreRequest clone() => GetScoreRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetScoreRequest copyWith(void Function(GetScoreRequest) updates) => super.copyWith((message) => updates(message as GetScoreRequest)) as GetScoreRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetScoreRequest create() => GetScoreRequest._();
  GetScoreRequest createEmptyInstance() => create();
  static $pb.PbList<GetScoreRequest> createRepeated() => $pb.PbList<GetScoreRequest>();
  @$core.pragma('dart2js:noInline')
  static GetScoreRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetScoreRequest>(create);
  static GetScoreRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get scoreId => $_getSZ(0);
  @$pb.TagNumber(1)
  set scoreId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasScoreId() => $_has(0);
  @$pb.TagNumber(1)
  void clearScoreId() => clearField(1);
}

class GetScoresRequest extends $pb.GeneratedMessage {
  factory GetScoresRequest({
    $3.Timestamp? changedSince,
    $core.int? pageSize,
  }) {
    final $result = create();
    if (changedSince != null) {
      $result.changedSince = changedSince;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    return $result;
  }
  GetScoresRequest._() : super();
  factory GetScoresRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetScoresRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetScoresRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOM<$3.Timestamp>(1, _omitFieldNames ? '' : 'changedSince', subBuilder: $3.Timestamp.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
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
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => clearField(2);
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
    Work? work,
    Movement? movement,
    Creators? creators,
    $core.Iterable<$core.String>? languages,
    $core.Iterable<$core.String>? instruments,
    $3.Timestamp? lastChangeTimestamp,
    $core.Iterable<$core.String>? tags,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (work != null) {
      $result.work = work;
    }
    if (movement != null) {
      $result.movement = movement;
    }
    if (creators != null) {
      $result.creators = creators;
    }
    if (languages != null) {
      $result.languages.addAll(languages);
    }
    if (instruments != null) {
      $result.instruments.addAll(instruments);
    }
    if (lastChangeTimestamp != null) {
      $result.lastChangeTimestamp = lastChangeTimestamp;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    return $result;
  }
  Score._() : super();
  factory Score.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Score.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Score', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<Work>(2, _omitFieldNames ? '' : 'work', subBuilder: Work.create)
    ..aOM<Movement>(3, _omitFieldNames ? '' : 'movement', subBuilder: Movement.create)
    ..aOM<Creators>(4, _omitFieldNames ? '' : 'creators', subBuilder: Creators.create)
    ..pPS(5, _omitFieldNames ? '' : 'languages')
    ..pPS(6, _omitFieldNames ? '' : 'instruments')
    ..aOM<$3.Timestamp>(7, _omitFieldNames ? '' : 'lastChangeTimestamp', subBuilder: $3.Timestamp.create)
    ..pPS(8, _omitFieldNames ? '' : 'tags')
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
  Work get work => $_getN(1);
  @$pb.TagNumber(2)
  set work(Work v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasWork() => $_has(1);
  @$pb.TagNumber(2)
  void clearWork() => clearField(2);
  @$pb.TagNumber(2)
  Work ensureWork() => $_ensure(1);

  @$pb.TagNumber(3)
  Movement get movement => $_getN(2);
  @$pb.TagNumber(3)
  set movement(Movement v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasMovement() => $_has(2);
  @$pb.TagNumber(3)
  void clearMovement() => clearField(3);
  @$pb.TagNumber(3)
  Movement ensureMovement() => $_ensure(2);

  @$pb.TagNumber(4)
  Creators get creators => $_getN(3);
  @$pb.TagNumber(4)
  set creators(Creators v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreators() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreators() => clearField(4);
  @$pb.TagNumber(4)
  Creators ensureCreators() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$core.String> get languages => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.String> get instruments => $_getList(5);

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

  @$pb.TagNumber(8)
  $core.List<$core.String> get tags => $_getList(7);
}

class Work extends $pb.GeneratedMessage {
  factory Work({
    $core.String? title,
    $core.String? number,
  }) {
    final $result = create();
    if (title != null) {
      $result.title = title;
    }
    if (number != null) {
      $result.number = number;
    }
    return $result;
  }
  Work._() : super();
  factory Work.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Work.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Work', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'number')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Work clone() => Work()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Work copyWith(void Function(Work) updates) => super.copyWith((message) => updates(message as Work)) as Work;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Work create() => Work._();
  Work createEmptyInstance() => create();
  static $pb.PbList<Work> createRepeated() => $pb.PbList<Work>();
  @$core.pragma('dart2js:noInline')
  static Work getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Work>(create);
  static Work? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get number => $_getSZ(1);
  @$pb.TagNumber(2)
  set number($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => clearField(2);
}

class Movement extends $pb.GeneratedMessage {
  factory Movement({
    $core.String? title,
    $core.String? number,
  }) {
    final $result = create();
    if (title != null) {
      $result.title = title;
    }
    if (number != null) {
      $result.number = number;
    }
    return $result;
  }
  Movement._() : super();
  factory Movement.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Movement.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Movement', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'number')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Movement clone() => Movement()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Movement copyWith(void Function(Movement) updates) => super.copyWith((message) => updates(message as Movement)) as Movement;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Movement create() => Movement._();
  Movement createEmptyInstance() => create();
  static $pb.PbList<Movement> createRepeated() => $pb.PbList<Movement>();
  @$core.pragma('dart2js:noInline')
  static Movement getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Movement>(create);
  static Movement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get number => $_getSZ(1);
  @$pb.TagNumber(2)
  set number($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => clearField(2);
}

class Creators extends $pb.GeneratedMessage {
  factory Creators({
    $core.Iterable<$core.String>? composers,
    $core.Iterable<$core.String>? lyricists,
  }) {
    final $result = create();
    if (composers != null) {
      $result.composers.addAll(composers);
    }
    if (lyricists != null) {
      $result.lyricists.addAll(lyricists);
    }
    return $result;
  }
  Creators._() : super();
  factory Creators.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Creators.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Creators', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'composers')
    ..pPS(2, _omitFieldNames ? '' : 'lyricists')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Creators clone() => Creators()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Creators copyWith(void Function(Creators) updates) => super.copyWith((message) => updates(message as Creators)) as Creators;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Creators create() => Creators._();
  Creators createEmptyInstance() => create();
  static $pb.PbList<Creators> createRepeated() => $pb.PbList<Creators>();
  @$core.pragma('dart2js:noInline')
  static Creators getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Creators>(create);
  static Creators? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get composers => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get lyricists => $_getList(1);
}

class FavouritesPage extends $pb.GeneratedMessage {
  factory FavouritesPage({
    $fixnum.Int64? totalHits,
    $core.Iterable<Favourite>? favourite,
  }) {
    final $result = create();
    if (totalHits != null) {
      $result.totalHits = totalHits;
    }
    if (favourite != null) {
      $result.favourite.addAll(favourite);
    }
    return $result;
  }
  FavouritesPage._() : super();
  factory FavouritesPage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FavouritesPage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FavouritesPage', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'totalHits')
    ..pc<Favourite>(2, _omitFieldNames ? '' : 'favourite', $pb.PbFieldType.PM, subBuilder: Favourite.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FavouritesPage clone() => FavouritesPage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FavouritesPage copyWith(void Function(FavouritesPage) updates) => super.copyWith((message) => updates(message as FavouritesPage)) as FavouritesPage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FavouritesPage create() => FavouritesPage._();
  FavouritesPage createEmptyInstance() => create();
  static $pb.PbList<FavouritesPage> createRepeated() => $pb.PbList<FavouritesPage>();
  @$core.pragma('dart2js:noInline')
  static FavouritesPage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FavouritesPage>(create);
  static FavouritesPage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get totalHits => $_getI64(0);
  @$pb.TagNumber(1)
  set totalHits($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTotalHits() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalHits() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Favourite> get favourite => $_getList(1);
}

class Favourite extends $pb.GeneratedMessage {
  factory Favourite({
    $core.String? scoreId,
    $3.Timestamp? favouritedAt,
  }) {
    final $result = create();
    if (scoreId != null) {
      $result.scoreId = scoreId;
    }
    if (favouritedAt != null) {
      $result.favouritedAt = favouritedAt;
    }
    return $result;
  }
  Favourite._() : super();
  factory Favourite.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Favourite.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Favourite', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'scoreId')
    ..aOM<$3.Timestamp>(2, _omitFieldNames ? '' : 'favouritedAt', subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Favourite clone() => Favourite()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Favourite copyWith(void Function(Favourite) updates) => super.copyWith((message) => updates(message as Favourite)) as Favourite;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Favourite create() => Favourite._();
  Favourite createEmptyInstance() => create();
  static $pb.PbList<Favourite> createRepeated() => $pb.PbList<Favourite>();
  @$core.pragma('dart2js:noInline')
  static Favourite getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Favourite>(create);
  static Favourite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get scoreId => $_getSZ(0);
  @$pb.TagNumber(1)
  set scoreId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasScoreId() => $_has(0);
  @$pb.TagNumber(1)
  void clearScoreId() => clearField(1);

  @$pb.TagNumber(2)
  $3.Timestamp get favouritedAt => $_getN(1);
  @$pb.TagNumber(2)
  set favouritedAt($3.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFavouritedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearFavouritedAt() => clearField(2);
  @$pb.TagNumber(2)
  $3.Timestamp ensureFavouritedAt() => $_ensure(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

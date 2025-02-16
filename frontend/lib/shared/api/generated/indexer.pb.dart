//
//  Generated code. Do not modify.
//  source: indexer.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $3;

class IndexScoresRequest extends $pb.GeneratedMessage {
  factory IndexScoresRequest({
    $3.Timestamp? since,
    $3.Timestamp? until,
  }) {
    final $result = create();
    if (since != null) {
      $result.since = since;
    }
    if (until != null) {
      $result.until = until;
    }
    return $result;
  }
  IndexScoresRequest._() : super();
  factory IndexScoresRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IndexScoresRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IndexScoresRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'score'), createEmptyInstance: create)
    ..aOM<$3.Timestamp>(1, _omitFieldNames ? '' : 'since', subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(2, _omitFieldNames ? '' : 'until', subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IndexScoresRequest clone() => IndexScoresRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IndexScoresRequest copyWith(void Function(IndexScoresRequest) updates) => super.copyWith((message) => updates(message as IndexScoresRequest)) as IndexScoresRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexScoresRequest create() => IndexScoresRequest._();
  IndexScoresRequest createEmptyInstance() => create();
  static $pb.PbList<IndexScoresRequest> createRepeated() => $pb.PbList<IndexScoresRequest>();
  @$core.pragma('dart2js:noInline')
  static IndexScoresRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexScoresRequest>(create);
  static IndexScoresRequest? _defaultInstance;

  /// Indicates the timestamp of the scores from which the index should start.
  /// All scores created/modified before this timestamp will be ignored.
  @$pb.TagNumber(1)
  $3.Timestamp get since => $_getN(0);
  @$pb.TagNumber(1)
  set since($3.Timestamp v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSince() => $_has(0);
  @$pb.TagNumber(1)
  void clearSince() => clearField(1);
  @$pb.TagNumber(1)
  $3.Timestamp ensureSince() => $_ensure(0);

  ///  Indicates the timestamp of the scores until which the index should include.
  ///  All scores created/modified after this timestamp will be ignored.
  ///
  ///  If this value is omitted, all scores created/modified until now will be
  ///  indexed.
  @$pb.TagNumber(2)
  $3.Timestamp get until => $_getN(1);
  @$pb.TagNumber(2)
  set until($3.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasUntil() => $_has(1);
  @$pb.TagNumber(2)
  void clearUntil() => clearField(2);
  @$pb.TagNumber(2)
  $3.Timestamp ensureUntil() => $_ensure(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

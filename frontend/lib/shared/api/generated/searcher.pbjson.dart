//
//  Generated code. Do not modify.
//  source: searcher.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getScoreRequestDescriptor instead')
const GetScoreRequest$json = {
  '1': 'GetScoreRequest',
  '2': [
    {'1': 'score_id', '3': 1, '4': 1, '5': 9, '10': 'scoreId'},
  ],
};

/// Descriptor for `GetScoreRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getScoreRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRTY29yZVJlcXVlc3QSGQoIc2NvcmVfaWQYASABKAlSB3Njb3JlSWQ=');

@$core.Deprecated('Use getScoresRequestDescriptor instead')
const GetScoresRequest$json = {
  '1': 'GetScoresRequest',
  '2': [
    {'1': 'changed_since', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'changedSince', '17': true},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
  ],
  '8': [
    {'1': '_changed_since'},
  ],
};

/// Descriptor for `GetScoresRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getScoresRequestDescriptor = $convert.base64Decode(
    'ChBHZXRTY29yZXNSZXF1ZXN0EkQKDWNoYW5nZWRfc2luY2UYASABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wSABSDGNoYW5nZWRTaW5jZYgBARIbCglwYWdlX3NpemUYAiABKAVSCHBh'
    'Z2VTaXplQhAKDl9jaGFuZ2VkX3NpbmNl');

@$core.Deprecated('Use scoresPageDescriptor instead')
const ScoresPage$json = {
  '1': 'ScoresPage',
  '2': [
    {'1': 'total_hits', '3': 1, '4': 1, '5': 3, '10': 'totalHits'},
    {'1': 'scores', '3': 2, '4': 3, '5': 11, '6': '.score.Score', '10': 'scores'},
  ],
};

/// Descriptor for `ScoresPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scoresPageDescriptor = $convert.base64Decode(
    'CgpTY29yZXNQYWdlEh0KCnRvdGFsX2hpdHMYASABKANSCXRvdGFsSGl0cxIkCgZzY29yZXMYAi'
    'ADKAsyDC5zY29yZS5TY29yZVIGc2NvcmVz');

@$core.Deprecated('Use scoreDescriptor instead')
const Score$json = {
  '1': 'Score',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'work', '3': 2, '4': 1, '5': 11, '6': '.score.Work', '10': 'work'},
    {'1': 'movement', '3': 3, '4': 1, '5': 11, '6': '.score.Movement', '10': 'movement'},
    {'1': 'creators', '3': 4, '4': 1, '5': 11, '6': '.score.Creators', '10': 'creators'},
    {'1': 'languages', '3': 5, '4': 3, '5': 9, '10': 'languages'},
    {'1': 'instruments', '3': 6, '4': 3, '5': 9, '10': 'instruments'},
    {'1': 'last_change_timestamp', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastChangeTimestamp'},
    {'1': 'tags', '3': 8, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `Score`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scoreDescriptor = $convert.base64Decode(
    'CgVTY29yZRIOCgJpZBgBIAEoCVICaWQSHwoEd29yaxgCIAEoCzILLnNjb3JlLldvcmtSBHdvcm'
    'sSKwoIbW92ZW1lbnQYAyABKAsyDy5zY29yZS5Nb3ZlbWVudFIIbW92ZW1lbnQSKwoIY3JlYXRv'
    'cnMYBCABKAsyDy5zY29yZS5DcmVhdG9yc1IIY3JlYXRvcnMSHAoJbGFuZ3VhZ2VzGAUgAygJUg'
    'lsYW5ndWFnZXMSIAoLaW5zdHJ1bWVudHMYBiADKAlSC2luc3RydW1lbnRzEk4KFWxhc3RfY2hh'
    'bmdlX3RpbWVzdGFtcBgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSE2xhc3RDaG'
    'FuZ2VUaW1lc3RhbXASEgoEdGFncxgIIAMoCVIEdGFncw==');

@$core.Deprecated('Use workDescriptor instead')
const Work$json = {
  '1': 'Work',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'number', '3': 2, '4': 1, '5': 9, '10': 'number'},
  ],
};

/// Descriptor for `Work`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workDescriptor = $convert.base64Decode(
    'CgRXb3JrEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIWCgZudW1iZXIYAiABKAlSBm51bWJlcg==');

@$core.Deprecated('Use movementDescriptor instead')
const Movement$json = {
  '1': 'Movement',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'number', '3': 2, '4': 1, '5': 9, '10': 'number'},
  ],
};

/// Descriptor for `Movement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List movementDescriptor = $convert.base64Decode(
    'CghNb3ZlbWVudBIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSFgoGbnVtYmVyGAIgASgJUgZudW1iZX'
    'I=');

@$core.Deprecated('Use creatorsDescriptor instead')
const Creators$json = {
  '1': 'Creators',
  '2': [
    {'1': 'composers', '3': 1, '4': 3, '5': 9, '10': 'composers'},
    {'1': 'lyricists', '3': 2, '4': 3, '5': 9, '10': 'lyricists'},
  ],
};

/// Descriptor for `Creators`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creatorsDescriptor = $convert.base64Decode(
    'CghDcmVhdG9ycxIcCgljb21wb3NlcnMYASADKAlSCWNvbXBvc2VycxIcCglseXJpY2lzdHMYAi'
    'ADKAlSCWx5cmljaXN0cw==');

@$core.Deprecated('Use favouritesPageDescriptor instead')
const FavouritesPage$json = {
  '1': 'FavouritesPage',
  '2': [
    {'1': 'total_hits', '3': 1, '4': 1, '5': 3, '10': 'totalHits'},
    {'1': 'favourite', '3': 2, '4': 3, '5': 11, '6': '.score.Favourite', '10': 'favourite'},
  ],
};

/// Descriptor for `FavouritesPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favouritesPageDescriptor = $convert.base64Decode(
    'Cg5GYXZvdXJpdGVzUGFnZRIdCgp0b3RhbF9oaXRzGAEgASgDUgl0b3RhbEhpdHMSLgoJZmF2b3'
    'VyaXRlGAIgAygLMhAuc2NvcmUuRmF2b3VyaXRlUglmYXZvdXJpdGU=');

@$core.Deprecated('Use favouriteDescriptor instead')
const Favourite$json = {
  '1': 'Favourite',
  '2': [
    {'1': 'score_id', '3': 1, '4': 1, '5': 9, '10': 'scoreId'},
    {'1': 'favourited_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'favouritedAt'},
  ],
};

/// Descriptor for `Favourite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favouriteDescriptor = $convert.base64Decode(
    'CglGYXZvdXJpdGUSGQoIc2NvcmVfaWQYASABKAlSB3Njb3JlSWQSPwoNZmF2b3VyaXRlZF9hdB'
    'gCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDGZhdm91cml0ZWRBdA==');


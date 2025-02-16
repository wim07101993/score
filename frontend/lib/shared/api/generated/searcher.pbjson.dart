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

@$core.Deprecated('Use getScoresRequestDescriptor instead')
const GetScoresRequest$json = {
  '1': 'GetScoresRequest',
  '2': [
    {'1': 'changed_since', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'changedSince', '17': true},
    {'1': 'only_favourites', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'onlyFavourites', '17': true},
  ],
  '8': [
    {'1': '_changed_since'},
    {'1': '_only_favourites'},
  ],
};

/// Descriptor for `GetScoresRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getScoresRequestDescriptor = $convert.base64Decode(
    'ChBHZXRTY29yZXNSZXF1ZXN0EkQKDWNoYW5nZWRfc2luY2UYASABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wSABSDGNoYW5nZWRTaW5jZYgBARIsCg9vbmx5X2Zhdm91cml0ZXMYAiAB'
    'KAhIAVIOb25seUZhdm91cml0ZXOIAQFCEAoOX2NoYW5nZWRfc2luY2VCEgoQX29ubHlfZmF2b3'
    'VyaXRlcw==');

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
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'composers', '3': 3, '4': 3, '5': 9, '10': 'composers'},
    {'1': 'lyricists', '3': 4, '4': 3, '5': 9, '10': 'lyricists'},
    {'1': 'instruments', '3': 5, '4': 3, '5': 9, '10': 'instruments'},
    {'1': 'isFavourite', '3': 6, '4': 1, '5': 8, '10': 'isFavourite'},
    {'1': 'last_change_timestamp', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastChangeTimestamp'},
  ],
};

/// Descriptor for `Score`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scoreDescriptor = $convert.base64Decode(
    'CgVTY29yZRIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhwKCWNvbXBvc2'
    'VycxgDIAMoCVIJY29tcG9zZXJzEhwKCWx5cmljaXN0cxgEIAMoCVIJbHlyaWNpc3RzEiAKC2lu'
    'c3RydW1lbnRzGAUgAygJUgtpbnN0cnVtZW50cxIgCgtpc0Zhdm91cml0ZRgGIAEoCFILaXNGYX'
    'ZvdXJpdGUSTgoVbGFzdF9jaGFuZ2VfdGltZXN0YW1wGAcgASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFITbGFzdENoYW5nZVRpbWVzdGFtcA==');


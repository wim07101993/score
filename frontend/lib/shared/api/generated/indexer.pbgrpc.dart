//
//  Generated code. Do not modify.
//  source: indexer.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/empty.pb.dart' as $1;
import 'indexer.pb.dart' as $0;

export 'indexer.pb.dart';

@$pb.GrpcServiceName('score.Indexer')
class IndexerClient extends $grpc.Client {
  static final _$indexScores = $grpc.ClientMethod<$0.IndexScoresRequest, $1.Empty>(
      '/score.Indexer/IndexScores',
      ($0.IndexScoresRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));

  IndexerClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$1.Empty> indexScores($0.IndexScoresRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$indexScores, request, options: options);
  }
}

@$pb.GrpcServiceName('score.Indexer')
abstract class IndexerServiceBase extends $grpc.Service {
  $core.String get $name => 'score.Indexer';

  IndexerServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.IndexScoresRequest, $1.Empty>(
        'IndexScores',
        indexScores_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IndexScoresRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$1.Empty> indexScores_Pre($grpc.ServiceCall call, $async.Future<$0.IndexScoresRequest> request) async {
    return indexScores(call, await request);
  }

  $async.Future<$1.Empty> indexScores($grpc.ServiceCall call, $0.IndexScoresRequest request);
}

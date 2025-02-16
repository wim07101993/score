//
//  Generated code. Do not modify.
//  source: searcher.proto
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

import 'searcher.pb.dart' as $2;

export 'searcher.pb.dart';

@$pb.GrpcServiceName('score.Searcher')
class SearcherClient extends $grpc.Client {
  static final _$getScores = $grpc.ClientMethod<$2.GetScoresRequest, $2.ScoresPage>(
      '/score.Searcher/GetScores',
      ($2.GetScoresRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ScoresPage.fromBuffer(value));

  SearcherClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseStream<$2.ScoresPage> getScores($2.GetScoresRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$getScores, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('score.Searcher')
abstract class SearcherServiceBase extends $grpc.Service {
  $core.String get $name => 'score.Searcher';

  SearcherServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.GetScoresRequest, $2.ScoresPage>(
        'GetScores',
        getScores_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $2.GetScoresRequest.fromBuffer(value),
        ($2.ScoresPage value) => value.writeToBuffer()));
  }

  $async.Stream<$2.ScoresPage> getScores_Pre($grpc.ServiceCall call, $async.Future<$2.GetScoresRequest> request) async* {
    yield* getScores(call, await request);
  }

  $async.Stream<$2.ScoresPage> getScores($grpc.ServiceCall call, $2.GetScoresRequest request);
}

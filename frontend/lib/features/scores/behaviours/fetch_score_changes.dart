import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:grpc/grpc.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart'
    show GetScoresRequest, SearcherClient;

class FetchScoreChanges extends Behaviour<FetchScoreChangesParams, void> {
  FetchScoreChanges({
    required super.monitor,
    required this.searcherClient,
  });

  final SearcherClient searcherClient;

  @override
  Future<void>? action(
    FetchScoreChangesParams input,
    BehaviourTrack? track,
  ) async {
    // final lastChangedTimestamp = await _getLastChangedTimestamp(scores);
    final responseStream = searcherClient.getScores(
      GetScoresRequest(
          // changedSince: lastChangedTimestamp != null
          //     ? Timestamp.fromDateTime(lastChangedTimestamp)
          //     : null,
          ),
      options: CallOptions(
        metadata: {'Authorization': 'Bearer ${input.authToken}'},
      ),
    );

    await for (final page in responseStream) {
      for (final score in page.scores) {
        print(score);
        // final existing = await scores.typedDocument<Score>(score.id);
        // final doc = _convertApiScoreToDbScore(
        //   score,
        //   existing != null && existing.isFavourite,
        // );
        // await scores.saveTypedDocument(doc).withConcurrencyControl();
      }
    }
  }
}

class FetchScoreChangesParams {
  const FetchScoreChangesParams({
    required this.authToken,
  });

  final String authToken;
}

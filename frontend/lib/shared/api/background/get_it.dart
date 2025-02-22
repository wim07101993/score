import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:score/app_settings.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/shared/api/background/fetch_score_changes.dart';
import 'package:score/shared/api/generated/indexer.pbgrpc.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart';

void registerApi() {
  GetIt.I.registerLazySingleton<ClientChannel>(
    () => ClientChannel(
      appSettings.scoreApi.host,
      port: appSettings.scoreApi.port,
      options: appSettings.scoreApi.channelOptions,
    ),
    dispose: (channel) => channel.shutdown(),
  );

  GetIt.I.registerLazySingleton<SearcherClient>(
    () => SearcherClient(GetIt.I<ClientChannel>()),
  );
  GetIt.I.registerLazySingleton<IndexerClient>(
    () => IndexerClient(GetIt.I<ClientChannel>()),
  );

  GetIt.I.registerFactory<SearcherClient>(
    () => SearcherClient(GetIt.I()),
  );

  GetIt.I.registerFactory<FetchScoreChanges>(
    () => FetchScoreChanges(
      monitor: GetIt.I(),
      searcherClient: GetIt.I(),
      scores: GetIt.I(instanceName: scoresCollectionInstance),
    ),
  );
}

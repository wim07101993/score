import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:score/app_settings.dart';
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
}

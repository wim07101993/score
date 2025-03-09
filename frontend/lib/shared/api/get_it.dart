import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:score/app_settings.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart';

void registerApi() {
  GetIt.I.registerLazySingleton<ClientChannel>(
    () => ClientChannel(
      appSettings.scoreApi.host,
      port: appSettings.scoreApi.port,
      options: const ChannelOptions(
        credentials: kDebugMode
            ? ChannelCredentials.insecure()
            : ChannelCredentials.secure(),
      ),
    ),
  );
  GetIt.I.registerFactory(() => SearcherClient(GetIt.I<ClientChannel>()));
}

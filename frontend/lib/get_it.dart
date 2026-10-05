import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:score/api.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/get_it.dart';
import 'package:score/features/collections/get_it.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/get_it.dart';
import 'package:score/features/settings/get_it.dart';
import 'package:score/features/sync/get_it.dart';
import 'package:score/router.dart';

extension GetItExtensions on GetIt {
  void registerDependencies() {
    this
      ..registerLogging()
      ..registerLogStorage()
      ..registerLazySingletonAsync(() => Config.load())
      ..registerLazySingletonAsync(() => LocalStore.open())
      ..registerLazySingleton<http.Client>(
        () => TimingOutClient(inner: http.Client()),
        dispose: (client) => client.close(),
      )
      ..registerLazySingleton(() => AppRouter())
      ..registerFeatures();
  }

  void registerFeatures() {
    this
      ..registerSettings()
      ..registerAuth()
      ..registerScores()
      ..registerSets()
      ..registerCollections()
      ..registerSync();
  }
}

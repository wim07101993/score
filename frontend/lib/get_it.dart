import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:score/config.dart';
import 'package:score/features/auth/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/storage/auth_key_value_store.dart';
import 'package:score/features/auth/storage/auth_tokens.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/get_it.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_store.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/get_it.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_store.dart';
import 'package:score/features/settings/get_it.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/features/sync/get_it.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/router.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/databases.dart';

extension GetItExtensions on GetIt {
  void registerDependencies() {
    this
      ..registerLogging()
      ..registerLogStorage()
      ..registerLazySingletonAsync(() => Config.load(logger: logger('Config')))
      ..registerLazySingletonAsync(() => Databases.open())
      ..registerLazySingletonAsync(() => ScoreDocuments.open())
      ..registerLazySingleton<http.Client>(
        () => TimingOutClient(inner: http.Client()),
        dispose: (client) => client.close(),
      )
      ..registerLazySingleton(() => AppRouter())
      ..registerFeatures();
  }

  void registerFeatures() {
    this
      // Every feature's API client is built by this one, which signs each
      // request with the token of the moment: see [AuthTokens].
      ..registerLazySingletonAsync<ApiClientFactory>(
        () async => ApiClientFactory(
          config: (await getAsync<Config>()).api,
          inner: get(),
          authToken: () async => (await getAsync<AuthTokens>())(),
        ),
      )
      ..registerSettings()
      ..registerAuth()
      ..registerScores()
      ..registerSets()
      ..registerCollections()
      ..registerSync();
  }

  /// Builds everything that is registered asynchronously and that a page or a
  /// behaviour asks for without waiting: the store, the clients, the sync
  /// engines and the notifiers. What is on this device is read here, before
  /// the first page, so that no page is drawn from an empty store.
  Future<void> resolveDependencies() async {
    await Future.wait([
      getAsync<Config>(),
      getAsync<Databases>(),
      getAsync<ScoresDatabase>(),
      getAsync<ScoreDocuments>(),
      getAsync<SetsStore>(),
      getAsync<CollectionsStore>(),
      getAsync<SyncHoldsStore>(),
      getAsync<SettingsStore>(),
      getAsync<AuthKeyValueStore>(),
      getAsync<OidcApi>(),
      getAsync<ScoresApi>(),
      getAsync<SetsApi>(),
      getAsync<CollectionsApi>(),
      getAsync<SetsEngine>(),
      getAsync<CollectionsEngine>(),
      getAsync<SettingsNotifier>(),
      getAsync<AuthNotifier>(),
      getAsync<ScoresNotifier>(),
      getAsync<SetsNotifier>(),
      getAsync<CollectionsNotifier>(),
    ]);
  }
}

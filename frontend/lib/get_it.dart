import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authentication_exception.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/auth/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/get_it.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/features/sets/get_it.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/features/settings/get_it.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/features/sync/get_it.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';
import 'package:score/features/sync/sync_engine.dart';
import 'package:score/router.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/databases.dart';

extension GetItExtensions on GetIt {
  void registerDependencies() {
    this
      ..registerLogging()
      ..registerLogStorage()
      ..registerLazySingletonAsync(() => Config.load())
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
      ..registerLazySingletonAsync<ApiClientFactory>(
        () async => ApiClientFactory(
          config: (await getAsync<Config>()).api,
          inner: get(),
          authToken: () async {
            final user = (await get<Authenticate>()(
              const AuthenticateParams(mayAskTheUser: false),
            )).orThrow();
            return user.accessToken ?? (throw const SignInRequired());
          },
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
  /// behaviour asks for without waiting: the store, the clients and the
  /// notifiers. What is on this device is read here, before
  /// the first page, so that no page is drawn from an empty store.
  Future<void> resolveDependencies() async {
    await Future.wait([
      getAsync<Config>(),
      getAsync<Databases>(),
      getAsync<ScoresDatabase>(),
      getAsync<ScoreDocuments>(),
      getAsync<SetsDatabase>(),
      getAsync<CollectionsDatabase>(),
      getAsync<SyncDatesStore>(),
      getAsync<SettingsStore>(),
      getAsync<OidcUserManager>(),
      getAsync<ScoresApi>(),
      getAsync<SetsApi>(),
      getAsync<CollectionsApi>(),
      getAsync<SettingsNotifier>(),
      getAsync<AuthNotifier>(),
      getAsync<ScoresNotifier>(),
      getAsync<SetsNotifier>(),
      getAsync<CollectionsNotifier>(),
      getAsync<SyncEngine>(),
    ]);
  }
}

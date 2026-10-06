import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/behaviours/forget_user.dart';
import 'package:score/features/auth/behaviours/go_on_as_kept_user.dart';
import 'package:score/features/auth/behaviours/say_if_no_longer_signed_in.dart';
import 'package:score/features/auth/behaviours/sign_out.dart';
import 'package:score/features/auth/behaviours/sign_outs.dart';
import 'package:score/features/auth/behaviours/update_auth.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/storage/auth_key_value_store.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/databases.dart';

extension AuthGetItExtensions on GetIt {
  void registerAuth() {
    registerLazySingletonAsync(
      () async =>
          AuthKeyValueStore(database: (await getAsync<Databases>()).data),
    );
    registerLazySingletonAsync<OidcApi>(
      () async => OidcApi(
        config: (await getAsync<Config>()).oidc,
        store: await getAsync<AuthKeyValueStore>(),
        client: get(),
      ),
    );
    registerFactory(() => AuthStore(store: get()));

    registerNotifier(
      () async => AuthNotifier(
        oidc: await getAsync<OidcApi>(),
        authStore: AuthStore(store: await getAsync<AuthKeyValueStore>()),
      ),
    );

    registerLazySingleton(() => SignOuts());
    registerFactory(
      () => GoOnAsKeptUser(monitor: get(), oidc: get(), authStore: get()),
    );
    registerFactory(
      () => UpdateAuth(
        monitor: get(),
        logger: logger('Auth'),
        oidc: get(),
        authStore: get(),
        signOuts: get(),
        forgetSets: get(),
        forgetCollections: get(),
      ),
    );
    registerFactory(
      () => ForgetUser(monitor: get(), oidc: get(), authStore: get()),
    );
    registerFactory(
      () => SignOut(
        monitor: get(),
        oidc: get(),
        authStore: get(),
        signOuts: get(),
        forgetSets: get(),
        forgetCollections: get(),
      ),
    );
    registerFactory(
      () => SayIfNoLongerSignedIn(monitor: get(), oidc: get(), authStore: get()),
    );
  }
}

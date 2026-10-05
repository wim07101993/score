import 'package:get_it/get_it.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/settings/settings.dart';

extension SettingsGetItExtensions on GetIt {
  void registerSettings() {
    registerLazySingletonAsync(
      () async => Settings.load(await getAsync<LocalStore>()),
      dispose: (settings) => settings.dispose(),
    );
  }
}

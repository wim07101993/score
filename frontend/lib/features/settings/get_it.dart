import 'package:get_it/get_it.dart';
import 'package:score/features/settings/behaviours/set_page_look.dart';
import 'package:score/features/settings/behaviours/set_theme_mode.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/databases.dart';

extension SettingsGetItExtensions on GetIt {
  void registerSettings() {
    registerLazySingletonAsync(
      () async => SettingsStore(database: (await getAsync<Databases>()).data),
    );
    registerNotifier(
      () async => SettingsNotifier(store: await getAsync<SettingsStore>()),
    );

    registerFactory(() => SetThemeMode(monitor: get(), store: get()));
    registerFactory(() => SetPageLook(monitor: get(), store: get()));
  }
}

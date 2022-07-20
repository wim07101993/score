import 'package:algolia/algolia.dart';
import 'package:score/app_get_it_extensions.dart';

class AlgoliaInstaller implements Installer {
  const AlgoliaInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(() => const Algolia.init(
        applicationId: 'QKWKN8AKUG',
        apiKey: '1d6d1fc0b40485ca149395e8f3b60979'));
  }
}

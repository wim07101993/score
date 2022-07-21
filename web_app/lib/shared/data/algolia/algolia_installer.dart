import 'package:algolia/algolia.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/shared/data/firebase/remote_config/app_config.dart';

class AlgoliaInstaller implements Installer {
  const AlgoliaInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    final config = getIt<AppConfig>().algolia;
    final instance = Algolia.init(
      applicationId: config.appId,
      apiKey: config.apiKey,
    );
    getIt.registerSingleton(instance);
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {}
}

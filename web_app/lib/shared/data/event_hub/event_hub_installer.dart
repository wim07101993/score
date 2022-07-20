import 'package:behaviour/behaviour.dart';
import 'package:hawk/hawk.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/shared/behaviours/standard_behaviour_monitor.dart';

class EventHubInstaller implements Installer {
  const EventHubInstaller();

  @override
  Future<void> initialize(GetIt getIt) => Future.value();

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(() => EventHub.instance);
    getIt.registerLazySingleton(() => getIt<EventHub>().handlers);
    getIt.registerFactory<BehaviourMonitor>(
        () => GetItBehaviourMonitor<StandardBehaviourTrack>(getIt: getIt));
    getIt.registerFactoryParam((BehaviourMixin behaviour, _) {
      return StandardBehaviourTrack(
        behaviour: behaviour,
        logger: getIt.logger(behaviour.runtimeType.toString()),
      );
    });
  }
}

import 'package:get_it/get_it.dart';
import 'package:score/notifiers/store_notifier.dart';

extension NotifierGetItExtensions on GetIt {
  /// Registers a notifier that is made the first time it is asked for, and
  /// handed out once it holds what the store holds: see [StreamNotifier.ready].
  void registerNotifier<T extends StreamNotifier<Object?>>(
    Future<T> Function() make,
  ) {
    registerLazySingletonAsync<T>(
      () async {
        final notifier = await make();
        await notifier.ready;
        return notifier;
      },
      dispose: (notifier) => notifier.dispose(),
    );
  }
}

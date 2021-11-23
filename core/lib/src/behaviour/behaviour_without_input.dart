import 'behaviour_base.dart';
import 'exception_or.dart';

abstract class BehaviourWithoutInput<T> extends BehaviourBase {
  BehaviourWithoutInput({
    required BehaviourDependencies dependencies,
  }) : super(dependencies);

  Future<ExceptionOr<T>> call() {
    return executeAction(() async => Success(await action()));
  }

  Future<T> action();
}

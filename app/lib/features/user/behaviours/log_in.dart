import 'package:core/core.dart';

class LogIn extends BehaviourWithoutInput<void> {
  LogIn({
    Logger errorLogger,
  }) : super(errorLogger: errorLogger);

  @override
  Future action() {
    // TODO: implement action
    throw UnimplementedError();
  }

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    // TODO: implement onFailed
    throw UnimplementedError();
  }
}

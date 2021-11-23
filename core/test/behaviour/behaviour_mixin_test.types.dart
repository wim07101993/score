part of 'behaviour_mixin_test.dart';

class _MockSimpleBehaviour extends Mock implements _SimpleBehaviour {}

class _SimpleBehaviour with BehaviourMixin {
  _SimpleBehaviour({
    required this.description,
    required this.firebasePerformance,
    required this.logger,
  });

  @override
  final String description;

  @override
  final FirebasePerformance firebasePerformance;

  @override
  final Logger logger;

  @override
  Future<Exception> onError(Object e, StackTrace stacktrace) {
    return Future.value(Exception());
  }
}

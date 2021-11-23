import 'package:core/core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:testing/mocks/packages.dart';
import 'package:testing/testing.dart';

part 'behaviour_mixin_test.types.dart';

void main() {
  late final String fakeDescription;
  late final MockFirebasePerformance mockFirebasePerformance;
  late final MockLogger mockLogger;
  late final BehaviourMixin behaviour;

  setUp(() {
    fakeDescription = faker.lorem.sentence();

    mockFirebasePerformance = MockFirebasePerformance();
    mockLogger = MockLogger();

    behaviour = _SimpleBehaviour(
      description: fakeDescription,
      firebasePerformance: mockFirebasePerformance,
      logger: mockLogger,
    );
  });

  group('tag', () {
    test('should return the runtime type', () {
      // assert
      expect(behaviour.tag, (_SimpleBehaviour).toString());
    });
  });
}

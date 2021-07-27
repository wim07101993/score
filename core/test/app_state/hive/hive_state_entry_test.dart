import 'package:core/src/app_state/hive/hive_state_entry.dart';
import 'package:testing/mocks/packages.dart';
import 'package:testing/testing.dart';

void main() {
  late String fakeKey;
  late Object fakeDefaultValue;
  late MockBox mockBox;

  late HiveStateEntry hiveState;

  setUp(() {
    fakeKey = faker.lorem.word();
    fakeDefaultValue = faker.randomObject();

    mockBox = MockBox();

    hiveState = HiveStateEntry(
      box: mockBox,
      key: fakeKey,
      defaultValue: fakeDefaultValue,
    );
  });

  group('set', () {
    test('should put the value in the box', () async {
      // arrange
      final fakeValue = faker.randomObject();
      when(() => mockBox.put(any(), any())).thenAnswer((i) => Future.value());

      // act
      await hiveState.set(fakeValue);

      // assert
      verify(() => mockBox.put(fakeKey, fakeValue));
    });
  });
}

import 'dart:async';

import 'package:core/core.dart';
import 'package:testing/mocks/packages.dart';
import 'package:testing/testing.dart';

void main() {
  late String fakeKey;
  late String fakeDefaultValue;

  late MockBox mockBox;

  late ReadOnlyHiveStateEntry<String> readOnlyHiveStateEntry;

  setUp(() {
    fakeKey = faker.lorem.word();
    fakeDefaultValue = faker.lorem.sentence();

    mockBox = MockBox();

    readOnlyHiveStateEntry = ReadOnlyHiveStateEntry(
      box: mockBox,
      key: fakeKey,
      defaultValue: fakeDefaultValue,
    );
  });

  group('call', () {
    late String fakeValue;

    setUp(() {
      fakeValue = faker.lorem.sentence();
      when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(fakeValue);
    });

    test('should get the value from the box', () {
      // act
      final value = readOnlyHiveStateEntry();

      // assert
      expect(value, fakeValue);
      verify(() => mockBox.get(fakeKey, defaultValue: fakeDefaultValue));
    });

    test('should return default value if value is not [T]', () {
      // arrange
      when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(faker.randomGenerator.integer(100));
      when(() => mockBox.put(any(), any())).thenAnswer((i) => Future.value());

      // act
      final value = readOnlyHiveStateEntry();

      // assert
      expect(value, fakeDefaultValue);
      verify(() => mockBox.put(fakeKey, fakeDefaultValue));
    });

    test(
        'should not set the value if default value is equal to the current value',
        () {
      // arrange
      final readOnlyHiveStateEntry = ReadOnlyHiveStateEntry<String?>(
        box: mockBox,
        key: fakeKey,
        defaultValue: null,
      );
      when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(null);

      // act
      readOnlyHiveStateEntry();

      // assert
      verifyNever(() => mockBox.put(fakeKey, fakeDefaultValue));
    });
  });

  group('changes', () {
    late StreamController<BoxEvent> fakeWatchStream;

    setUp(() {
      fakeWatchStream = StreamController();
      when(() => mockBox.watch(key: any(named: 'key')))
          .thenAnswer((i) => fakeWatchStream.stream);
    });

    test('should return the changes from the box', () async {
      // arrange
      final fakeValue = faker.lorem.sentence();

      // act
      final stream = readOnlyHiveStateEntry.changes;

      // assert later
      expectLater(stream, emits(fakeValue));

      // act
      fakeWatchStream.add(BoxEvent(
        faker.lorem.word(),
        fakeValue,
        faker.randomGenerator.boolean(),
      ));
    });

    test('should return default value if stream value is not T', () async {
      // act
      final stream = readOnlyHiveStateEntry.changes;

      // assert later
      expectLater(stream, emits(fakeDefaultValue));

      // act
      fakeWatchStream.add(BoxEvent(
        faker.lorem.word(),
        faker.randomGenerator.integer(100),
        faker.randomGenerator.boolean(),
      ));
    });
  });
}

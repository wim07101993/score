import 'package:core/src/app_state/read_only_state_entry_proxy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/mocks/core.dart';
import 'package:testing/testing.dart';

void main() {
  late MockStateEntry mockStateEntry;

  late ReadOnlyStateEntryProxy entry;

  setUp(() {
    mockStateEntry = MockStateEntry();

    entry = ReadOnlyStateEntryProxy(
      call: mockStateEntry.call,
      changes: () => mockStateEntry.changes,
    );
  });

  group('call', () {
    test('should call the parent', () {
      // arrange
      final fakeValue = faker.randomObject();
      when(() => mockStateEntry()).thenReturn(fakeValue);

      // act
      final value = entry();

      // assert
      expect(value, fakeValue);
      verify(() => mockStateEntry());
    });
  });

  group('changes', () {
    test('should get the changes from the parent', () {
      // arrange
      final fakeStream = Stream.value(faker.randomObject());
      when(() => mockStateEntry.changes).thenAnswer((i) => fakeStream);

      // act
      final changes = entry.changes;

      // assert
      expect(changes, fakeStream);
    });
  });
}

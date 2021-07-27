import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/mocks/core.dart';
import 'package:testing/testing.dart';

abstract class _Converter<TIn, TOut> {
  TOut convert(TIn input);
  TIn convertBack(TOut input);
}

class MockConverter<TIn, TOut> extends Mock implements _Converter<TIn, TOut> {}

void main() {
  late MockStateEntry mockFromEntry;
  late MockConverter mockConverter;
  late ConvertingStateEntry entry;

  setUp(() {
    mockFromEntry = MockStateEntry();
    mockConverter = MockConverter();

    entry = ConvertingStateEntry(
      fromEntry: mockFromEntry,
      convertToStorage: mockConverter.convert,
      convertFromStorage: mockConverter.convertBack,
    );
  });

  group('call', () {
    test('should return the converted value from the entry', () {
      // arrange
      final fakeValue = faker.randomObject();
      final fakeStorageValue = faker.randomObject();
      when(() => mockFromEntry()).thenReturn(fakeStorageValue);
      when(() => mockConverter.convertBack(any())).thenReturn(fakeValue);

      // act
      final value = entry();

      // assert
      expect(value, fakeValue);
      verify(() => mockConverter.convertBack(fakeStorageValue));
      verify(() => mockFromEntry());
    });
  });

  group('changes', () {
    test('should return a mapped stream', () async {
      // arrange
      final streamController = StreamController();
      final fakeValue = faker.randomObject();
      final fakeStorageValue = faker.randomObject();
      when(() => mockFromEntry.changes)
          .thenAnswer((i) => streamController.stream);
      when(() => mockConverter.convertBack(any())).thenReturn(fakeValue);

      // act
      final changes = entry.changes;

      // assert later
      expectLater(changes, emits(fakeValue));

      // act
      streamController.add(fakeStorageValue);
      await untilCalled(() => mockConverter.convertBack(any()));

      // assert
      verify(() => mockConverter.convertBack(fakeStorageValue));
    });
  });

  group('set', () {
    test('should set the converted value', () {
      // arrange
      final fakeValue = faker.randomObject();
      final fakeStorageValue = faker.randomObject();
      when(() => mockFromEntry.set(any())).thenAnswer((i) => Future.value());
      when(() => mockConverter.convert(any())).thenReturn(fakeStorageValue);

      // act
      entry.set(fakeValue);

      // assert
      verify(() => mockConverter.convert(fakeValue));
      verify(() => mockFromEntry.set(fakeStorageValue));
    });
  });
}

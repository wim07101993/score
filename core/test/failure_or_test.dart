import 'package:core/core.dart';
import 'package:core/src/failure_or.dart';
import 'package:testing/testing.dart';

abstract class _IfFailure<TResult> {
  TResult call(Failure failure);
}

abstract class _IfSuccess<T, TResult> {
  TResult call(T value);
}

class MockIfFailure<TResult> extends Mock implements _IfFailure<TResult> {}

class MockIfSuccess<T, TResult> extends Mock implements _IfSuccess<T, TResult> {
}

void main() {
  setUpAll(() {
    registerFallbackValue(const FakeFailure());
  });

  group(Failed, () {
    late Failure failure;
    late Failed failed;

    setUp(() {
      failure = faker.failure();

      failed = Failed(failure);
    });

    group('fold', () {
      test('should return [ifFailure] result', () {
        // arrange
        final mockIfFailure = MockIfFailure();
        final mockIfSuccess = MockIfSuccess();
        final fakeResult = faker.randomObject();
        when(() => mockIfFailure(any())).thenReturn(fakeResult);

        // act
        final result = failed.fold(
          mockIfFailure.call,
          mockIfSuccess.call,
        );

        // arrange
        expect(result, fakeResult);
        verify(() => mockIfFailure.call(failure));
        verifyNever(() => mockIfSuccess.call(any()));
      });
    });

    group('==', () {
      test(
        'should equal a failed object with the same failure',
        () => expect(failed, Failed(failure)),
      );
    });
  });

  group(Success, () {
    late dynamic value;
    late Success success;

    setUp(() {
      value = faker.randomObject();

      success = Success(value);
    });

    group('fold', () {
      test('should return [ifFailure] result', () {
        // arrange
        final mockIfFailure = MockIfFailure();
        final mockIfSuccess = MockIfSuccess();
        final fakeResult = faker.randomObject();
        when(() => mockIfSuccess(any())).thenReturn(fakeResult);

        // act
        final result = success.fold(
          mockIfFailure.call,
          mockIfSuccess.call,
        );

        // arrange
        expect(result, fakeResult);
        verifyNever(() => mockIfFailure.call(any()));
        verify(() => mockIfSuccess.call(value));
      });
    });

    group('==', () {
      test(
        'should equal a success object with the same value',
        () => expect(success, Success(value)),
      );
    });
  });
}

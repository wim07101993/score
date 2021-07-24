import 'package:core/core.dart';
import 'package:faker/faker.dart';

import 'fake_failure.dart';

final faker = Faker();

class _UnknownObject {}

extension TestingFakerExtensions on Faker {
  Failure failure() => const FakeFailure();

  Object randomObject() {
    return randomGenerator.element([
      lorem.sentence(),
      randomGenerator.integer(10000),
      randomGenerator.boolean(),
      randomGenerator.decimal(
        min: randomGenerator.integer(1000),
        scale: randomGenerator.integer(1000),
      ),
      randomGenerator.string(1000),
      address,
      guid.guid(),
      _UnknownObject(),
    ]);
  }
}

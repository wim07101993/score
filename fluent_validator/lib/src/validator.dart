
abstract class Validator<T> {
  const Validator();

  String? validate(T value);
}

mixin ValidatorMixin<T> implements Validator<T>{
  bool isValid(T value);

  String errorMessage()
}


class AndValidator<T> implements Validator<T> {
  const AndValidator(this.validators);

  final List<Validator<T>> validators;

  String? validate(T value) {
    for (final validator in validators) {
      final error = validator.validate(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

class OrValidator<T> implements Validator<T> {
  const OrValidator(this.validators);

  final List<Validator<T>> validators;

  String? validate(T value) {
    final first
    for (final validator in validators) {
      final error = validator.validate(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
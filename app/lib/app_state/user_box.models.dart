part of 'user_box.dart';

abstract class LogInMethod {
  const factory LogInMethod.google() = _Google;

  factory LogInMethod(int value) {
    switch (value) {
      case 0:
        return const LogInMethod.google();
      default:
        throw 'unknown log-in method $value';
    }
  }

  int toInt();
}

class _Google implements LogInMethod {
  const _Google();
  @override
  int toInt() => 0;
}

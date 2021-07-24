import 'package:flutter/widgets.dart';

abstract class Failure {
  const factory Failure.easy(
    String Function(BuildContext) messageBuilder,
  ) = EasyFailure;
  const factory Failure.unknown() = UnknownFailure;

  String getMessage(BuildContext context);
}

class EasyFailure implements Failure {
  const EasyFailure(this.messageBuilder);

  final String Function(BuildContext) messageBuilder;

  @override
  String getMessage(BuildContext context) => messageBuilder(context);
}

class UnknownFailure implements Failure {
  const UnknownFailure();

  @override
  String getMessage(BuildContext context) {
    // TODO translations
    return 'Something went wrong...';
  }
}

class CombinedFailure implements Failure {
  const CombinedFailure(this.failures);

  final Iterable<Failure> failures;

  @override
  String getMessage(BuildContext context) {
    return failures.map((f) => f.getMessage(context)).join('\r\n');
  }
}

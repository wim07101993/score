import 'package:core/core.dart';

class FakeFailure implements Failure {
  const FakeFailure([this.message = 'this is a fake failure']);

  final String message;

  @override
  String getMessage(BuildContext context) => message;
}

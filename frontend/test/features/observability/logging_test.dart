import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:score/features/observability/get_it.dart';

void main() {
  test("the app's own loggers log at every level", () {
    expect(GetIt.I.logger('Ours').isLoggable(Level.FINEST), isTrue);
  });

  test("a package's details are not logged, its warnings are", () {
    GetIt.I.logger('Ours');
    // What the sign-in library logs below a warning includes the answers of
    // the token endpoint, tokens and all.
    final package = Logger('openid_client');

    expect(package.isLoggable(Level.FINE), isFalse);
    expect(package.isLoggable(Level.WARNING), isTrue);
  });
}

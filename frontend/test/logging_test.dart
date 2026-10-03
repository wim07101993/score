import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/logging.dart';

void main() {
  test("the app's own loggers are kept at every level", () {
    appLogger('Ours');
    const filter = AppLogFilter(Level.ALL);

    expect(filter.shouldLog(LogRecord(Level.FINEST, 'a step', 'Ours')), isTrue);
  });

  test("a package's details are not kept, its warnings are", () {
    // What the sign-in library logs below a warning includes the answers of
    // the token endpoint, tokens and all.
    const filter = AppLogFilter(Level.ALL);

    expect(
      filter.shouldLog(
        LogRecord(Level.FINE, 'POST /token: {"refresh_token": "x"}',
            'openid_client'),
      ),
      isFalse,
    );
    expect(
      filter.shouldLog(LogRecord(Level.WARNING, 'it broke', 'openid_client')),
      isTrue,
    );
  });

  test('nothing below the minimum is kept, whoever said it', () {
    appLogger('Ours');
    const filter = AppLogFilter(Level.INFO);

    expect(filter.shouldLog(LogRecord(Level.FINE, 'a step', 'Ours')), isFalse);
    expect(filter.shouldLog(LogRecord(Level.INFO, 'news', 'Ours')), isTrue);
  });
}

import 'dart:async';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/observability/stored_logs.dart';
import 'package:score/features/sembast/local_store.dart';

void main() {
  late LocalStore store;

  setUp(() async => store = await LocalStore.inMemory());

  /// Logs [records] through a sink over [store], as one run of the app, and
  /// waits for them to have been written.
  Future<LogsController> run(List<LogRecord> records) async {
    final logs = LogsController();
    final sink = StoredLogSink(Future.value(store), logs);
    await sink.restored;
    for (final record in records) {
      logs.addLog(record);
      await sink.log(record);
    }
    return logs;
  }

  test('what was logged is there in the next run, before what it logs', () async {
    await run([
      LogRecord(Level.INFO, 'started', 'score.App'),
      LogRecord(Level.SEVERE, 'it broke', 'score.Sync', 'boom'),
    ]);

    final logs = await run([LogRecord(Level.INFO, 'started', 'score.App')]);

    expect(
      logs.value.map((record) => '${record.loggerName}: ${record.message}'),
      [
        'score.App: started',
        'score.Sync: it broke',
        'score.App: started',
      ],
    );
    final broke = logs.value.elementAt(1);
    expect(broke.level, Level.SEVERE);
    expect(broke.error, 'boom');
  });

  test('a record keeps the moment it was logged', () async {
    final logged = LogRecord(Level.INFO, 'then', 'score.App');
    await run([logged]);

    final logs = await run([]);

    expect(logs.value.single.time, logged.time);
  });

  test('records logged before the store has opened are kept too', () async {
    final opened = Completer<LocalStore>();
    final logs = LogsController();
    final sink = StoredLogSink(opened.future, logs);

    final logging = sink.log(LogRecord(Level.INFO, 'early', 'score.App'));
    opened.complete(store);
    await logging;

    expect((await store.readLogs()).single['message'], 'early');
  });

  test('only the last ones are kept for the next run', () async {
    await run([
      for (var i = 0; i < StoredLogSink.keptCount + 5; i++)
        LogRecord(Level.FINE, '$i', 'score.App'),
    ]);

    await run([]);
    final kept = await store.readLogs();

    expect(kept, hasLength(StoredLogSink.keptCount));
    expect(kept.last['message'], '${StoredLogSink.keptCount + 4}');
  });
}

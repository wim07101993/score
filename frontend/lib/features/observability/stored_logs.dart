import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/features/sembast/local_store.dart';

/// Keeps what is logged in the local store, so that what led up to a crash can
/// still be read once the app is started again.
///
/// Every record is written as it is logged, one after the other: a record
/// held back to be written with the next ones is a record a crash takes with
/// it, and those are the ones that are wanted.
///
/// When the store has opened, what earlier runs of the app logged is put in
/// front of what this one has logged so far in [logs], which is what the logs
/// page shows.
class StoredLogSink with LogSinkMixin {
  StoredLogSink(Future<LocalStore> store, LogsController logs) {
    _written = restored = store.then((store) async {
      _store = store;
      await store.keepLastLogs(keptCount);
      final earlier = await store.readLogs();
      logs.value = [...earlier.map(_fromJson), ...logs.value];
    });
  }

  /// Done when what earlier runs logged is in the logs page.
  late final Future<void> restored;

  /// How many records are kept: as many as the logs page holds.
  static const keptCount = LogsController.maxLogCount;

  @override
  LogFilter get filter => const LogFilter.none();

  late LocalStore _store;

  /// The last write, which the next one waits for, so that the records are
  /// stored in the order they were logged.
  late Future<void> _written;

  var _writtenSinceTrimmed = 0;

  @override
  Future<void> write(LogRecord logRecord) {
    final json = _toJson(logRecord);
    return _written = _written.then((_) async {
      await _store.writeLog(json);
      // Trimmed now and then rather than at every write: the store holds
      // somewhere between one and two pages of logs, and a write is a write.
      if (++_writtenSinceTrimmed >= keptCount) {
        _writtenSinceTrimmed = 0;
        await _store.keepLastLogs(keptCount);
      }
    });
  }

  static Map<String, Object?> _toJson(LogRecord record) => {
        'time': record.time.toIso8601String(),
        'level': record.level.name,
        'levelValue': record.level.value,
        'logger': record.loggerName,
        'message': record.message,
        'error': ?record.error?.toString(),
        'stackTrace': ?record.stackTrace?.toString(),
      };

  static LogRecord _fromJson(Map<String, Object?> json) {
    final name = json['level']! as String;
    final value = json['levelValue']! as int;
    final stackTrace = json['stackTrace'] as String?;
    return _StoredLogRecord(
      DateTime.parse(json['time']! as String),
      Level.LEVELS.firstWhere(
        (level) => level.value == value,
        orElse: () => Level(name, value),
      ),
      json['message']! as String,
      json['logger']! as String,
      json['error'],
      stackTrace == null ? null : StackTrace.fromString(stackTrace),
    );
  }
}

/// A record logged by an earlier run, at the moment it was logged rather than
/// the moment it was read back.
class _StoredLogRecord extends LogRecord {
  _StoredLogRecord(
    this._time,
    super.level,
    super.message,
    super.loggerName, [
    super.error,
    super.stackTrace,
  ]);

  final DateTime _time;

  @override
  DateTime get time => _time;
}

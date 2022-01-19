import 'package:flutter/material.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:provider/provider.dart';
import 'package:score/data/logging/hive_log_sink.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LogsScreen.stream(
      stream: getLogRecordStream(context),
    );
  }

  Stream<LogRecord> getLogRecordStream(BuildContext context) async* {
    final hiveLogSink = context.read<HiveLogSink>();
    final currentItems = await hiveLogSink.getAll();
    for (final record in currentItems) {
      yield record;
    }
    yield* hiveLogSink.additions();
  }
}

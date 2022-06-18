import 'package:flutter/material.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:provider/provider.dart';
import 'package:score/shared/data/logging/hive_log_sink.dart';

class LogsPage extends Page {
  const LogsPage({
    super.key,
  }) : super(name: 'developer-options/logs');

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) => LogsScreen.stream(
        stream: getLogRecordStream(context),
      ),
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

import 'package:flutter_fox_logging/flutter_fox_logging.dart';

class FutureLogsControllerLogSink extends LogSink {
  FutureLogsControllerLogSink({
    required this.controller,
  });

  final Future<LogsController> controller;

  @override
  Future<void> write(LogRecord logRecord) {
    return controller.then((controller) => controller.addLog(logRecord));
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';

/// What the app has logged: in this run, and in the ones before it.
@RoutePage()
class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      LogsScreen(controller: GetIt.I<LogsController>());
}

import 'package:auto_route/annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart' as fox;
import 'package:get_it/get_it.dart';

@RoutePage()
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return fox.LogsScreen(controller: GetIt.I());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/logging.dart';

/// The way to what the app has logged since it started.
///
/// For when something does not sync and somebody asks what the app says: on a
/// phone or a tablet there is no console to look in, and this is the console.
class LogsButton extends StatelessWidget {
  const LogsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logs',
      icon: const Icon(Icons.receipt_long_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => LogsScreen(controller: logs),
        ),
      ),
    );
  }
}

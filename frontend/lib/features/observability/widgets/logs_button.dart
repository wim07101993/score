import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router.dart';

class const LogsButton({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logs',
      icon: const Icon(Icons.receipt_long_outlined),
      onPressed: () => context.router.push(const LogsRoute()),
    );
  }
}

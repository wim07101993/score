import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';

class const ApiReachableIndicator({
  super.key,
  required final Future<ExceptionOr<bool>> Function() check,
}) extends StatefulWidget {
  @override
  State<ApiReachableIndicator> createState() => _ApiReachableIndicatorState();
}

class _ApiReachableIndicatorState extends State<ApiReachableIndicator> {
  bool isRefreshing = false;
  bool? value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  Future<void> refresh() async {
    if (!mounted || isRefreshing) {
      return;
    }
    try {
      isRefreshing = true;
      setState(() => value = null);
      final result = await widget.check();
      if (!mounted) {
        return;
      }
      setState(() {
        value = switch (result) {
          Success(:final value) => value,
          Failed() => false,
        };
      });
    } finally {
      isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (value) {
      case true:
        return Tooltip(
          message: 'Can be reached. Tap to refresh.',
          child: IconButton(
            onPressed: refresh,
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
            ),
          ),
        );
      case false:
        return Tooltip(
          message: 'Cannot be reached. Tap to try again.',
          child: IconButton(
            onPressed: refresh,
            icon: Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
          ),
        );
      case null:
        return const Tooltip(
          message: 'Still checking…',
          child: Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
    }
  }
}

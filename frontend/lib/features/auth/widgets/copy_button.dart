import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class const CopyButton({
  super.key,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy',
      onPressed: value.isEmpty
          ? null
          : () => Clipboard.setData(ClipboardData(text: value)),
      icon: const Icon(Icons.copy),
    );
  }
}

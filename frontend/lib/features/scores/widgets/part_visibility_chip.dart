import 'package:flutter/material.dart';

/// Whether one part of the score is on this player's screen.
class const PartVisibilityChip({
  super.key,
  required final String name,
  required final bool visible,
  required final ValueChanged<bool> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(name),
      selected: visible,
      onSelected: onSelected,
    );
  }
}

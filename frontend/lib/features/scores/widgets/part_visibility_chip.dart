import 'package:flutter/material.dart';

/// Whether one part of the score is on this player's screen.
class PartVisibilityChip extends StatelessWidget {
  const PartVisibilityChip({
    super.key,
    required this.name,
    required this.visible,
    required this.onSelected,
  });

  final String name;
  final bool visible;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(name),
      selected: visible,
      onSelected: onSelected,
    );
  }
}

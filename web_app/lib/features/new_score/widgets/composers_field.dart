import 'package:flutter/material.dart';

class ComposersField extends StatelessWidget {
  const ComposersField({
    super.key,
    required this.values,
    required this.addComposer,
    required this.removeComposer,
  });

  final List<TextEditingController> values;
  final VoidCallback addComposer;
  final void Function(int index) removeComposer;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

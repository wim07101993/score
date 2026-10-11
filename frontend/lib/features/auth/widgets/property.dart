import 'package:flutter/material.dart';

class const Property({
  super.key,
  required final String name,
  required final String value,
  final Widget? trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(name),
      subtitle: SelectableText(value),
      trailing: trailing,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class EditableTextListItem extends StatelessWidget {
  const EditableTextListItem({
    Key? key,
    required this.controller,
    required this.label,
    required this.validator,
    required this.onRemove,
  }) : super(key: key);

  final TextEditingController controller;
  final String label;
  final Iterable Function(String? value) validator;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            validator: (value) => _validate(s, value),
            decoration: InputDecoration(
              labelText: label,
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.remove_circle,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  String? _validate(S s, String? value) {
    final errors = validator(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }
    return errors.map(s.getErrorMessage).join('\r\n');
  }
}

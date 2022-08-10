import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/widgets/editable_list/editable_list_simple_field.dart';

class EditableListTextItem extends StatelessWidget {
  const EditableListTextItem({
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
    return EditableListSimpleField(
      onRemove: onRemove,
      child: TextFormField(
        controller: controller,
        validator: (value) => _validate(s, value),
        decoration: InputDecoration(
          labelText: label,
        ),
        textInputAction: TextInputAction.next,
      ),
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

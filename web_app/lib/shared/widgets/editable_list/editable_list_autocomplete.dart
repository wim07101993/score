import 'dart:async';

import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class EditableListAutocomplete<T extends Object> extends StatelessWidget {
  const EditableListAutocomplete({
    Key? key,
    required this.optionsBuilder,
    required this.displayStringForOption,
    required this.controller,
    required this.label,
    required this.onRemove,
    this.validator,
  }) : super(key: key);

  final FutureOr<Iterable<T>> Function(TextEditingValue textEditingValue)
      optionsBuilder;
  final String Function(T option) displayStringForOption;
  final ValueNotifier<T?> controller;
  final String label;
  final Iterable Function(T? value)? validator;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final initialOption = controller.value;
    final initialValue =
        initialOption == null ? null : displayStringForOption(initialOption);
    return Row(children: [
      Expanded(
        child: Autocomplete<T>(
          displayStringForOption: displayStringForOption,
          initialValue: initialValue == null
              ? null
              : TextEditingValue(text: initialValue),
          onSelected: (option) => controller.value = option,
          optionsBuilder: optionsBuilder,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return _AutocompleteTextField<T>(
              controller: controller,
              focusNode: focusNode,
              label: label,
              onFieldSubmitted: onSubmitted,
              validator: _validate,
            );
          },
        ),
      ),
      IconButton(
        onPressed: onRemove,
        icon: Icon(
          Icons.remove_circle,
          color: theme.colorScheme.secondary,
        ),
      ),
    ]);
  }

  Iterable _validate(String? value) {}
}

class _AutocompleteTextField<T> extends StatelessWidget {
  const _AutocompleteTextField({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onFieldSubmitted,
    required this.validator,
    required this.label,
  });

  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final TextEditingController controller;
  final Iterable Function(String? value)? validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: controller,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: label,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  String? _validate(S s, String? value) {
    final validator = this.validator;
    if (validator == null) {
      return null;
    }
    final errors = validator(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }
    return errors.map(s.getErrorMessage).join('\r\n');
  }
}

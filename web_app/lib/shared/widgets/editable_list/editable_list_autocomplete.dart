import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/globals.dart';
import 'package:score/shared/list_extensions.dart';
import 'package:score/shared/widgets/editable_list/editable_list_simple_field.dart';

class EditableListAutocomplete<T extends Object> extends StatefulWidget {
  const EditableListAutocomplete({
    Key? key,
    required this.possibleOptions,
    required this.controller,
    required this.label,
    required this.onRemove,
    required this.validator,
  }) : super(key: key);

  final Map<T, String> possibleOptions;
  final ValueNotifier<T?> controller;
  final String label;
  final Iterable Function(T? value) validator;
  final VoidCallback onRemove;

  @override
  State<EditableListAutocomplete<T>> createState() =>
      _EditableListAutocompleteState<T>();
}

class _EditableListAutocompleteState<T extends Object>
    extends State<EditableListAutocomplete<T>> {
  late List<MapEntry<String, T>> searchMap;

  @override
  void initState() {
    super.initState();
    updatePossibleStringValues();
  }

  @override
  void didUpdateWidget(covariant EditableListAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    updatePossibleStringValues();
  }

  void updatePossibleStringValues() {
    searchMap = widget.possibleOptions.entries
        .mapMany(createSearchEntries)
        .toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  Iterable<MapEntry<String, T>> createSearchEntries(
    MapEntry<T, String> entry,
  ) sync* {
    final stringValue = entry.value.toLowerCase();
    yield MapEntry(stringValue, entry.key);
    yield* stringValue
        .split(RegExp(r'[\s.]'))
        .map((part) => MapEntry(part, entry.key));
  }

  @override
  Widget build(BuildContext context) {
    final initialOption = widget.controller.value;
    final initialValue =
        initialOption == null ? null : widget.possibleOptions[initialOption];
    return EditableListSimpleField(
      onRemove: widget.onRemove,
      child: Autocomplete<T>(
        initialValue:
            initialValue == null ? null : TextEditingValue(text: initialValue),
        onSelected: (option) => widget.controller.value = option,
        optionsBuilder: buildOptions,
        displayStringForOption: (opt) => widget.possibleOptions[opt] ?? '',
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return _AutocompleteTextField<T>(
            controller: controller,
            focusNode: focusNode,
            label: widget.label,
            onFieldSubmitted: onSubmitted,
            parseOption: (str) =>
                searchMap.firstWhere((entry) => entry.key == str).value,
            validator: widget.validator,
          );
        },
      ),
    );
  }

  FutureOr<Iterable<T>> buildOptions(TextEditingValue textEditingValue) {
    final value = textEditingValue.text.toLowerCase();
    if (value.isEmpty) {
      return searchMap.map((entry) => entry.value).distinct();
    }
    return searchMap
        .where((entry) => entry.key.startsWith(textEditingValue.text))
        .map((entry) => entry.value)
        .distinct();
  }
}

class _AutocompleteTextField<T> extends StatelessWidget {
  const _AutocompleteTextField({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onFieldSubmitted,
    required this.label,
    required this.parseOption,
    required this.validator,
  });

  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final TextEditingController controller;
  final T Function(String? value) parseOption;
  final Iterable Function(T? value) validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: label,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  String? _validate(S s, String? value) {
    final option = parseOption(value);
    final errors = validator(option).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }
    return errors.map(s.getErrorMessage).join('\r\n');
  }
}

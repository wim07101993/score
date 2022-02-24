import 'package:flutter/cupertino.dart';

class EditableNotes {
  const EditableNotes({
    required this.controller,
  });

  final TextEditingController controller;

  String get value => controller.text;

  bool isValidate(String value) => value.isNotEmpty && value.length < 10000;
}

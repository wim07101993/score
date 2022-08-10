import 'package:flutter/material.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';
import 'package:score/shared/widgets/editable_list/editable_list_text_item.dart';

class EditableTextList extends EditableList<TextEditingController> {
  EditableTextList({
    required super.items,
    required super.maxNumberOfItems,
    required super.addButtonText,
    required super.tooManyItemsText,
    required super.label,
    required String itemLabel,
    required Iterable Function(String? validator) validator,
  }) : super(
          itemFactory: () => TextEditingController(),
          itemBuilder: (context, items, i) => EditableListTextItem(
            label: itemLabel,
            controller: items[i],
            onRemove: () => items.removeAt(i),
            validator: validator,
          ),
        );
}

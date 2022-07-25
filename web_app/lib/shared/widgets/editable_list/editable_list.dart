import 'package:flutter/material.dart';
import 'package:score/shared/list_notifier.dart';
import 'package:score/shared/widgets/editable_list/add_button.dart';

class EditableList<T> extends StatelessWidget {
  const EditableList({
    super.key,
    required this.items,
    required this.itemFactory,
    required this.itemBuilder,
    required this.maxNumberOfItems,
    required this.addButtonText,
    required this.tooManyItemsText,
    required this.label,
  });

  final ListNotifier<T> items;
  final T Function() itemFactory;
  final Widget Function(
    BuildContext context,
    ListNotifier<T> items,
    int index,
  ) itemBuilder;
  final int maxNumberOfItems;
  final String addButtonText;
  final String tooManyItemsText;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.headline6),
        ValueListenableBuilder<List<T>>(
          valueListenable: items,
          builder: (context, composers, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < composers.length; i++) ...[
                itemBuilder(context, items, i),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AddButton(
                    canPress: composers.length < maxNumberOfItems,
                    onPressed: () => items.add(itemFactory()),
                    text: addButtonText,
                    tooManyItemsText: tooManyItemsText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:score/features/new_score/models/draft_score.dart';
import 'package:score/features/new_score/widgets/add_composer_button.dart';
import 'package:score/features/new_score/widgets/composer_field.dart';

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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          _composerField(theme, i),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AddComposerButton(
              canAddComposers: values.length < DraftScore.maxNumberOfComposers,
              addComposer: addComposer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _composerField(ThemeData theme, int index) {
    return Row(children: [
      Expanded(child: ComposerField(value: values[index])),
      IconButton(
        onPressed: () => removeComposer(index),
        icon: Icon(
          Icons.remove_circle,
          color: theme.colorScheme.secondary,
        ),
      ),
    ]);
  }
}

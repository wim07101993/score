import 'package:flutter/material.dart';
import 'package:score/features/new_score/models/draft_score.dart';
import 'package:score/features/new_score/widgets/add_tag_button.dart';
import 'package:score/features/new_score/widgets/tag_field.dart';

class TagsField extends StatelessWidget {
  const TagsField({
    super.key,
    required this.values,
    required this.addTag,
    required this.removeTag,
  });

  final List<TextEditingController> values;
  final VoidCallback addTag;
  final void Function(int index) removeTag;

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
            child: AddTagButton(
              canAddTags: values.length < DraftScore.maxNumberOfTags,
              addTag: addTag,
            ),
          ),
        ),
      ],
    );
  }

  Widget _composerField(ThemeData theme, int index) {
    return Row(children: [
      Expanded(child: TagField(value: values[index])),
      IconButton(
        onPressed: () => removeTag(index),
        icon: Icon(
          Icons.remove_circle,
          color: theme.colorScheme.secondary,
        ),
      ),
    ]);
  }
}

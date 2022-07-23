import 'package:flutter/material.dart';
import 'package:score/features/new_score/widgets/add_tag_button.dart';
import 'package:score/features/new_score/widgets/tag_field.dart';
import 'package:score/shared/models/score.dart';

class TagsField extends StatefulWidget {
  const TagsField({
    super.key,
    required this.values,
  });

  final List<TextEditingController> values;

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.values.length; i++) ...[
          _composerField(theme, i),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AddTagButton(
              canAddTags: widget.values.length < Score.maxNumberOfTags,
              addTag: () {
                setState(() => widget.values.add(TextEditingController()));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _composerField(ThemeData theme, int index) {
    return Row(children: [
      Expanded(child: TagField(value: widget.values[index])),
      IconButton(
        onPressed: () => setState(() => widget.values.removeAt(index)),
        icon: Icon(
          Icons.remove_circle,
          color: theme.colorScheme.secondary,
        ),
      ),
    ]);
  }
}

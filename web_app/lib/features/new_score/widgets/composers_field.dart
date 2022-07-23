import 'package:flutter/material.dart';
import 'package:score/features/new_score/widgets/add_composer_button.dart';
import 'package:score/features/new_score/widgets/composer_field.dart';
import 'package:score/shared/models/score.dart';

class ComposersField extends StatefulWidget {
  const ComposersField({
    super.key,
    required this.values,
  });

  final List<TextEditingController> values;

  @override
  State<ComposersField> createState() => _ComposersFieldState();
}

class _ComposersFieldState extends State<ComposersField> {
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
            child: AddComposerButton(
              canAddComposers:
                  widget.values.length < Score.maxNumberOfComposers,
              addComposer: () {
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
      Expanded(child: ComposerField(value: widget.values[index])),
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

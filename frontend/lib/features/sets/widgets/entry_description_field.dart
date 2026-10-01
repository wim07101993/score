import 'package:flutter/material.dart';

/// The note next to one song of the set.
class EntryDescriptionField extends StatefulWidget {
  const EntryDescriptionField({
    super.key,
    required this.initialValue,
    required this.enabled,
    required this.onSubmitted,
  });

  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  State<EntryDescriptionField> createState() => _EntryDescriptionFieldState();
}

class _EntryDescriptionFieldState extends State<EntryDescriptionField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  /// The note as it read when this field last took it from the set, which is
  /// what the text is compared with to tell whether the player changed it.
  ///
  /// Taken in [initState] rather than left `late` with an initialiser: that
  /// would be read for the first time in [didUpdateWidget], when the widget
  /// already holds the note a sync brought in, and the field would take the
  /// new note for the one it started with — keep showing the old one, and
  /// write it back over the new one the moment somebody left the field.
  late String _taken;

  /// Leaving the field is done with it as much as pressing enter is: a note
  /// typed and then left for the next control, or for the page before, is a
  /// note the player meant to keep. There is no save button for it.
  late final FocusNode _focus = FocusNode()..addListener(_submitWhenLeft);

  void _submitWhenLeft() {
    if (!_focus.hasFocus) {
      _submit(_controller.text);
    }
  }

  @override
  void initState() {
    super.initState();
    _taken = widget.initialValue;
  }

  @override
  void didUpdateWidget(EntryDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The note can change underneath the field — a sync bringing in what
    // somebody wrote on another device. What the player has not touched takes
    // that on; what they are typing is theirs until they are done with it.
    if (widget.initialValue != oldWidget.initialValue &&
        _controller.text == _taken) {
      _controller.text = widget.initialValue;
      _taken = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    // Pressing enter on a note nobody changed is not a write: it would only
    // send back what this field last read, over whatever came in since.
    if (text == _taken) {
      return;
    }
    _taken = text;
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'capo 2, second verse only, straight into the next',
      ),
      // On submitted rather than on changed: every one of these is a write of
      // that song, and a write per keystroke is a write per keystroke.
      onSubmitted: _submit,
    );
  }
}

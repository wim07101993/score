import 'package:flutter/material.dart';

/// What is written next to one piece of the collection.
class const CollectionEntryDescriptionField({
  super.key,
  required final String initialValue,

  required final bool enabled,
  required final ValueChanged<String> onSubmitted,
}) extends StatefulWidget {
  @override
  State<CollectionEntryDescriptionField> createState() =>
      _CollectionEntryDescriptionFieldState();
}

class _CollectionEntryDescriptionFieldState
    extends State<CollectionEntryDescriptionField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  /// What is written next to the piece as this field last took it from the
  /// collection, which is what the text is compared with to tell whether the
  /// player changed it.
  ///
  /// Taken in [initState], not left to a `late` initialiser: that would first
  /// be read in [didUpdateWidget], once the widget already holds what a sync
  /// brought in, and the field would keep showing what was there before and
  /// write it back over the new text as soon as somebody left the field.
  late String _taken;

  /// Leaving the field is done with it as much as pressing enter is: what was
  /// typed and then left for the next control, or for the page before, is
  /// meant to be kept. There is no save button for it.
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
  void didUpdateWidget(CollectionEntryDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A sync can bring in what somebody else wrote next to the piece. What
    // the player has not touched takes that on; what they are typing is
    // theirs until they are done with it.
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text == _taken) {
      _controller.text = widget.initialValue;
      _taken = widget.initialValue;
    }
  }

  @override
  void dispose() {
    // Thrown away while still being typed in, which says nothing about being
    // done with it: on a phone, tapping "done" or going back does not take the
    // focus off the field first, and the field is gone before it would hear.
    // What was typed is kept rather than lost with it — unless it is a name
    // emptied out, which [_submit] would only have put back.
    _focus.removeListener(_submitWhenLeft);
    final value = _controller.text;
    if (value != _taken) {
      _taken = value;
      widget.onSubmitted(value);
    }
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    // Pressing enter on — or leaving — text nobody changed is not a write: it
    // would only send back what this field last read, over whatever came in
    // since.
    if (value == _taken) {
      return;
    }
    _taken = value;
    widget.onSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'page 214, in the red folder, the arrangement we do',
      ),
      // On submitted rather than on changed: every one of these is a write of
      // that piece, and a write per keystroke is a write per keystroke.
      onSubmitted: _submit,
    );
  }
}

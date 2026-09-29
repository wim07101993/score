import 'package:flutter/material.dart';

/// What is written next to one piece of the collection.
///
/// For a piece with no score this is not a note about it, it is its name, so
/// it says so — and it cannot be emptied: a book has nowhere for a piece to
/// come, so an unnamed one could not be found or told from the next unnamed
/// one. Emptying it puts the name back rather than refusing out loud; nobody
/// meant to leave a piece of a book with nothing to call it, they meant to type
/// over it.
class CollectionEntryDescriptionField extends StatefulWidget {
  const CollectionEntryDescriptionField({
    super.key,
    required this.initialValue,
    required this.isTheOnlyName,
    required this.enabled,
    required this.onSubmitted,
  });

  final String initialValue;

  /// Whether this is all the piece is called, which it is when it has no
  /// score to take a title from.
  final bool isTheOnlyName;

  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  State<CollectionEntryDescriptionField> createState() =>
      _CollectionEntryDescriptionFieldState();
}

class _CollectionEntryDescriptionFieldState
    extends State<CollectionEntryDescriptionField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(CollectionEntryDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A sync can bring in what somebody else wrote next to the piece. It is
    // taken only when it is different from what was there, so that what is
    // being typed is not thrown away by a redraw that changes nothing.
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (widget.isTheOnlyName && value.trim().isEmpty) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      return;
    }
    widget.onSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.isTheOnlyName
            ? 'what this piece is called'
            : 'page 214, in the red folder, the arrangement we do',
      ),
      // On submitted rather than on changed: every one of these is a write of
      // that piece, and a write per keystroke is a write per keystroke.
      onSubmitted: _submit,
    );
  }
}

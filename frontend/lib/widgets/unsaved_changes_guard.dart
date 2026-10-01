import 'package:flutter/material.dart';
import 'package:score/widgets/leave_page_warning.dart';

/// Asks before a page with edits that are not saved is left, and lets the
/// player go back to it rather than lose them.
///
/// Going back in the app asks in a dialog of its own. Closing or reloading the
/// tab on the web is the browser's to ask about, and it does, in its own words:
/// see [warnBeforeLeavingThePage].
class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.unsaved,
    required this.child,
  });

  /// Whether there is anything that would be lost.
  final bool unsaved;

  final Widget child;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  /// Stops the browser asking, once there is nothing left to ask about.
  VoidCallback? _stopWarning;

  @override
  void initState() {
    super.initState();
    _warnWhileUnsaved();
  }

  @override
  void didUpdateWidget(UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unsaved != widget.unsaved) _warnWhileUnsaved();
  }

  @override
  void dispose() {
    _stopWarning?.call();
    super.dispose();
  }

  void _warnWhileUnsaved() {
    _stopWarning?.call();
    _stopWarning = widget.unsaved ? warnBeforeLeavingThePage() : null;
  }

  Future<void> _askBeforeLeaving() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('What you changed here has not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _stopWarning?.call();
      _stopWarning = null;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !widget.unsaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askBeforeLeaving();
      },
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';

/// Says that the server cannot be reached, above a list drawn from what this
/// device has — so that a list that is empty, or short, is read as what this
/// device knows rather than as all there is.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'The server cannot be reached. What is here is what this device'
          ' knows; edits are kept and sent as soon as it can be reached again.',
        ),
      ),
    );
  }
}

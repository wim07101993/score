import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/sync/behaviours/syncer.dart';
import 'package:score/features/sync/sync_engine.dart';
import 'package:score/widgets/error_snack_bar.dart';

/// Syncs everything on this device with the server now, rather than at the
/// next page that happens to ask for it.
class const SyncButton({
  super.key,
}) extends StatefulWidget {
  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _busy = false;

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final results = await GetIt.I<SyncEngine>().sync();
      final problem = results
          .map(
            (result) => switch (result) {
              Failed(reason: NoConnectionSyncerException()) =>
                'The server cannot be reached right now.',
              Failed(reason: NotAuthenticatedSyncerException()) =>
                'Not signed in; sign in again to sync.',
              _ => null,
            },
          )
          .nonNulls
          .firstOrNull;
      if (problem != null) {
        messenger.showSnackBar(errorSnackBar(problem));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sync with the server',
      onPressed: _busy ? null : _sync,
      icon: _busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
    );
  }
}

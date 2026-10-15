import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/sync/notifiers/is_syncing_notifier.dart';
import 'package:score/features/sync/sync_engine.dart';

/// Syncs everything on this device with the server now, rather than at the
/// next page that happens to ask for it.
class const SyncButton({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: GetIt.I<IsSyncingNotifier>(),
      builder: (context, isSyncing, _) => IconButton(
        tooltip: 'Sync with the server',
        onPressed: isSyncing ? null : GetIt.I<SyncEngine>().sync,
        icon: isSyncing
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
      ),
    );
  }
}

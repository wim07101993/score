import 'package:flutter/material.dart';
import 'package:score/app.dart';
import 'package:score/widgets/error_snack_bar.dart';

/// Syncs everything on this device with the server now, rather than at the
/// next page that happens to ask for it.
///
/// The syncs themselves swallow what goes wrong, so whether anything did is
/// asked again here — whether the server could be reached, and whether there
/// is still a sign-in to send things with — and said only when it did.
class SyncButton extends StatefulWidget {
  const SyncButton({
    super.key,
  });

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _busy = false;

  Future<void> _sync() async {
    final app = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await app.syncEverything();
      // A sync that went through says so by the spinner stopping and the list
      // changing; only one that could not happen is worth interrupting for.
      final problem = !await app.scoresApi.canBeReached()
          ? 'The server cannot be reached right now.'
          : !await app.oidc.canBeReached()
              ? 'The sign-in provider cannot be reached right now.'
              : app.authProblem != null || !await app.oidc.holdsAToken()
                  ? 'Not signed in; sign in again to sync.'
                  : null;
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

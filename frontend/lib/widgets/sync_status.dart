import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/sync/behaviours/check_connection.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';

/// Where a set or a collection stands with the server, in the bar of its page.
///
/// While something about it is not synced, that is a button: "not synced yet"
/// on its own says that something is wrong and nothing about what, and a
/// player who has been looking at it for a day wants to know whether to wait
/// for the network, sign in again, or ask somebody.
class const SyncStatus({
  super.key,
  required final String label,

  /// Whether anything about it is still to be synced.
  required final bool unsynced,

  /// Why the last try left it unsynced, as the store has it: see
  /// [SyncEngine.whyNotSynced].
  required final WhyNotSynced? Function() whyNotSynced,

  /// Syncs it now.
  required final Future<void> Function() sync,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!unsynced) {
      return Center(child: Text(label));
    }
    return TextButton.icon(
      icon: const Icon(Icons.cloud_off, size: 18),
      label: Text(label),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _WhyNotSynced(
          whyNotSynced: whyNotSynced,
          sync: sync,
        ),
      ),
    );
  }
}

/// What is known about why it is not synced: what can be asked right now —
/// whether the server is there, whether there is anyone signed in to send it
/// as — and what the last try ran into.
class const _WhyNotSynced({
  required final WhyNotSynced? Function() whyNotSynced,
  required final Future<void> Function() sync,
}) extends StatefulWidget {
  @override
  State<_WhyNotSynced> createState() => _WhyNotSyncedState();
}

/// One reason, and what can be done about it.
typedef _Reason = ({String text, bool signIn});

class _WhyNotSyncedState extends State<_WhyNotSynced> {
  late Future<_Reason> _reason = _find();
  bool _busy = false;

  Future<_Reason> _find() async {
    final connection =
        (await GetIt.I<CheckConnection>()()).valueOrNull ??
        // Not known, rather than not there: what the last try ran into is
        // still worth saying.
        (server: true, provider: true, signedIn: true);
    if (!connection.server) {
      return (
        text:
            'The server cannot be reached from this device right now. What'
            ' you changed is kept here, and goes as soon as it can.',
        signIn: false,
      );
    }
    if (!connection.provider) {
      return (
        text:
            'The sign-in provider cannot be reached from this device right'
            ' now, and nothing can be sent without it. What you changed is'
            ' kept here, and goes as soon as it can.',
        signIn: false,
      );
    }
    if (!connection.signedIn) {
      return (
        text:
            'This device is no longer signed in, so there is nothing to send'
            ' it with. Sign in again, and it goes straight after.',
        signIn: true,
      );
    }
    return switch (widget.whyNotSynced()) {
      null => (
        text:
            'It has not been tried since the app was started. It goes at'
            ' the next sync — or now.',
        signIn: false,
      ),
      WhyNotSynced(hold: SyncHold.unreachable) => (
        text: 'The server could not be reached the last time it was tried.',
        signIn: false,
      ),
      WhyNotSynced(hold: SyncHold.noToken) => (
        text:
            'There was no sign-in to send it with the last time it was'
            ' tried. Sign in again, and it goes straight after.',
        signIn: true,
      ),
      WhyNotSynced(:final error?) => (
        text: 'The last try ran into this: $error',
        signIn: false,
      ),
      WhyNotSynced(status: 401) => (
        text:
            'The server did not take this sign-in the last time it was'
            ' tried. Sign in again, and it goes straight after.',
        signIn: true,
      ),
      WhyNotSynced(status: null, :final detail) => (
        text: 'Nothing answered the last time it was tried: $detail',
        signIn: false,
      ),
      WhyNotSynced(:final status, :final detail) => (
        text:
            'The server answered $status the last time it was tried:'
            ' $detail',
        signIn: false,
      ),
    };
  }

  Future<void> _act(bool signIn) async {
    setState(() => _busy = true);
    try {
      if (signIn) {
        await GetIt.I<Authenticate>()(const AuthenticateParams());
      }
      await widget.sync();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _reason = _find();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Reason>(
      future: _reason,
      builder: (context, snapshot) {
        final reason = snapshot.data;
        return AlertDialog(
          title: const Text('Not synced yet'),
          content: _busy || reason == null
              ? const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Text(reason.text),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (reason != null)
              FilledButton(
                onPressed: _busy ? null : () => _act(reason.signIn),
                child: Text(reason.signIn ? 'Sign in again' : 'Sync now'),
              ),
          ],
        );
      },
    );
  }
}

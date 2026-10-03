import 'package:flutter/material.dart';
import 'package:score/api.dart';
import 'package:score/app.dart';
import 'package:score/features/sync/engine.dart';

/// Where a set or a collection stands with the server, in the bar of its page.
///
/// While something about it is not synced, that is a button: "not synced yet"
/// on its own says that something is wrong and nothing about what, and a
/// player who has been looking at it for a day wants to know whether to wait
/// for the network, sign in again, or ask somebody.
class SyncStatus extends StatelessWidget {
  const SyncStatus({
    super.key,
    required this.label,
    required this.unsynced,
    required this.whyNotSynced,
    required this.apiCanBeReached,
    required this.sync,
  });

  final String label;

  /// Whether anything about it is still to be synced.
  final bool unsynced;

  /// Why the last try left it unsynced, as the sync engine remembers it: see
  /// [SyncEngine.whyNotSynced].
  final Object? Function() whyNotSynced;

  final Future<bool> Function() apiCanBeReached;

  /// Syncs it now.
  final Future<void> Function() sync;

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
          apiCanBeReached: apiCanBeReached,
          sync: sync,
        ),
      ),
    );
  }
}

/// What is known about why it is not synced: what can be asked right now —
/// whether the server is there, whether there is anyone signed in to send it
/// as — and what the last try ran into.
class _WhyNotSynced extends StatefulWidget {
  const _WhyNotSynced({
    required this.whyNotSynced,
    required this.apiCanBeReached,
    required this.sync,
  });

  final Object? Function() whyNotSynced;
  final Future<bool> Function() apiCanBeReached;
  final Future<void> Function() sync;

  @override
  State<_WhyNotSynced> createState() => _WhyNotSyncedState();
}

/// One reason, and what can be done about it.
typedef _Reason = ({String text, bool signIn});

class _WhyNotSyncedState extends State<_WhyNotSynced> {
  late Future<_Reason> _reason = _find();
  bool _busy = false;

  Future<_Reason> _find() async {
    final app = AppScope.read(context);
    final reachable = await Future.wait([
      widget.apiCanBeReached(),
      app.oidc.canBeReached(),
    ]);
    if (!reachable[0]) {
      return (
        text: 'The server cannot be reached from this device right now. What'
            ' you changed is kept here, and goes as soon as it can.',
        signIn: false,
      );
    }
    if (!reachable[1]) {
      return (
        text: 'The sign-in provider cannot be reached from this device right'
            ' now, and nothing can be sent without it. What you changed is'
            ' kept here, and goes as soon as it can.',
        signIn: false,
      );
    }
    if (!await app.oidc.holdsAToken()) {
      return (
        text: 'This device is no longer signed in, so there is nothing to send'
            ' it with. Sign in again, and it goes straight after.',
        signIn: true,
      );
    }
    if (!await app.oidc.holdsTheDataOfTheSignedInUser()) {
      return (
        text: 'What is on this device belongs to another account than the one'
            ' signed in, and is not sent as this one.',
        signIn: false,
      );
    }

    return switch (widget.whyNotSynced()) {
      null => (
          text: 'It has not been tried since the app was started. It goes at'
              ' the next sync — or now.',
          signIn: false,
        ),
      SyncHold.unreachable => (
          text: 'The server could not be reached the last time it was tried.',
          signIn: false,
        ),
      SyncHold.noToken => (
          text: 'There was no sign-in to send it with the last time it was'
              ' tried. Sign in again, and it goes straight after.',
          signIn: true,
        ),
      SyncHold.notTheirs => (
          text: 'What is on this device belonged to another account than the'
              ' one signed in the last time it was tried.',
          signIn: false,
        ),
      ApiException(status: 401) => (
          text: 'The server did not take this sign-in the last time it was'
              ' tried. Sign in again, and it goes straight after.',
          signIn: true,
        ),
      ApiException(status: null) && final error => (
          text: 'Nothing answered the last time it was tried: ${error.detail}',
          signIn: false,
        ),
      ApiException(:final status?) && final error => (
          text: 'The server answered $status the last time it was tried:'
              ' ${error.detail}',
          signIn: false,
        ),
      final error => (
          text: 'The last try ran into this: $error',
          signIn: false,
        ),
    };
  }

  Future<void> _act(bool signIn) async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      if (signIn) await app.updateAuthAndCatchUp(retry: true);
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

import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/widgets/error_snack_bar.dart';

class const RefreshTokenButton({
  super.key,
}) extends StatefulWidget {
  @override
  State<RefreshTokenButton> createState() => _RefreshTokenButtonState();
}

class _RefreshTokenButtonState extends State<RefreshTokenButton> {
  bool _busy = false;

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result = await GetIt.I<Authenticate>()(
        const AuthenticateParams(mayAskTheUser: false, forceRefresh: true),
      );
      switch (result) {
        case Success():
          messenger.showSnackBar(
            const SnackBar(content: Text('Token refreshed')),
          );
        case Failed(:final reason):
          messenger.showSnackBar(errorSnackBar('$reason'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _refresh,
      icon: const Icon(Icons.refresh),
      label: const Text('Refresh token'),
    );
  }
}

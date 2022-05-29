import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/globals.dart';

class ProfileFields extends StatelessWidget {
  const ProfileFields({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<FirebaseAuth>();

    return Consumer<UserNotifier>(
      builder: (context, userNotifier, child) => FutureBuilder(
        future: userNotifier.initialized,
        builder: (context, snapShot) {
          if (!snapShot.hasData) {
            return const CircularProgressIndicator();
          }
          final user = userNotifier.user;
          if (user == null) {
            return Text(S.of(context)!.notLoggedIn);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAvatar(auth: auth),
              const SizedBox(height: 16),
              Align(child: Text(user.email)),
              const SizedBox(height: 16),
              Align(child: EditableUserDisplayName(auth: auth)),
              const SizedBox(height: 16),
              DeleteAccountButton(
                auth: auth,
                onSignInRequired: () => _reauthenticate(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _reauthenticate(BuildContext context) {
    return showReauthenticateDialog(
      context: context,
      providerConfigs: context.read(),
      auth: context.read(),
      onSignedIn: () => Navigator.of(context).pop(true),
    );
  }
}

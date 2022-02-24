import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';

class LogOutButton extends StatelessWidget {
  const LogOutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => logout(context),
      icon: const Icon(Icons.logout_outlined),
    );
  }

  Future<void> logout(BuildContext context) async {
    await context.read<FirebaseAuth>().signOut().then((value) {
      FlutterFireUIAction.ofType<SignedOutAction>(context)?.callback(context);
    });
  }
}

import 'package:auto_route/annotations.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/features/auth/google_user_manager.dart';

@RoutePage()
class LogInScreen extends StatefulWidget {
  const LogInScreen({
    super.key,
    required this.redirect,
  });

  final Function(bool success) redirect;

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  bool isLoggingIn = false;

  Future<void> logIn(OidcUserManager userManager) async {
    if (isLoggingIn) {
      return;
    }
    setState(() => isLoggingIn = true);
    final exceptionOr = await GetIt.I.get<LogIn>()(userManager);
    if (!mounted) {
      return;
    }
    exceptionOr.when(
      (exception) => throw exception, // TODO: handle exception
      (user) => widget.redirect(user != null),
    );
    setState(() => isLoggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => logIn(GetIt.I.get<GoogleUserManager>()),
                child: const Text('LOG IN WITH GOOGLE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

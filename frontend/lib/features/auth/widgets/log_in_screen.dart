import 'package:auto_route/annotations.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/l10n/arb/app_localizations.dart';
import 'package:score/shared/widgets/exceptions.dart';

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
  Future<void> logIn() async {
    final locale = AppLocalizations.of(context)!.localeName;
    final login = await GetIt.I.getAsync<LogIn>();
    final exceptionOr = await login(LoginParams(locale: locale));
    if (!mounted) {
      return;
    }
    exceptionOr.when(
      (exception) => showUnknownError(),
      (user) => widget.redirect(user != null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => logIn(),
                child: Text(s.loginButtonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

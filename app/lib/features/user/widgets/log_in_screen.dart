import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:score/app_router.dart';
import 'package:score/features/user/bloc/log_in_bloc.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocListener<LogInBloc, LogInState>(
        listener: _onStateChange,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Score', style: theme.textTheme.headline1),
              Text(
                "An application to access Wim's sheet music",
                style: theme.textTheme.subtitle2,
              ),
              const SizedBox(height: 42),
              Text('Log in', style: theme.textTheme.headline5),
              const SizedBox(height: 8),
              SignInButton(
                Buttons.Google,
                onPressed: () => BlocProvider.of<LogInBloc>(context)
                    .add(const LogInEvent.logInWithGoogle()),
              ),
              const SizedBox(height: 16),
              Text('', style: theme.textTheme.headline1),
            ],
          ),
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, LogInState state) {
    if (state.failure != null) {
      showFailure(context, state.failure!);
    }
    final user = state.user;
    if (user != null) {
      if (user.accessLevels.application) {
        AutoRouter.of(context).replace(const HomeRoute());
      } else {
        AutoRouter.of(context).replace(const WaitingForAccessRoute());
      }
    }
  }
}

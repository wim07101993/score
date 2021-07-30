import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score/features/user/bloc/log_in_bloc.dart';

class LogInScreen extends StatelessWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => BlocProvider.of<LogInBloc>(context)
                  .add(const LogInEvent.logInWithGoogle()),
              child: const Text('Log in with google'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => BlocProvider.of<LogInBloc>(context)
                  .add(const LogInEvent.logInWithFacebook()),
              child: const Text('Log in with facebook'),
            ),
          ],
        ),
      ),
    );
  }
}

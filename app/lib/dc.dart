import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/behaviours/log_in_with_google.dart';
import 'package:score/features/user/bloc/log_in_bloc.dart';

export 'package:get_it/get_it.dart';

class ScoreAppProvider extends StatelessWidget {
  const ScoreAppProvider({
    Key? key,
    required this.getIt,
    required this.child,
  }) : super(key: key);

  final GetIt getIt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => getIt),
        Provider(create: (_) => getIt.logger),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt.logInBloc),
        ],
        child: child,
      ),
    );
  }
}

extension ScoreGetItExtensions on GetIt {
  LogInBloc get logInBloc => call();

  LogInWithGoogle get logInWithGoogle => call();

  GoogleSignIn get googleSignIn => call();
  Logger get logger => call();
  Logger get prettyLogger => call(instanceName: 'prettyLogger');

  Future<void> init() async {
    registerSingleton(this);
    registerLazySingleton(
      () => LogInWithGoogle(
        errorLogger: prettyLogger,
        googleSignIn: googleSignIn,
      ),
    );
    registerFactory(() => LogInBloc(logInWithGoogle: logInWithGoogle));
    registerLazySingleton(() => GoogleSignIn());
    registerLazySingleton(() => Logger(printer: SimplePrinter()));
    registerLazySingleton(() => Logger(printer: PrettyPrinter()),
        instanceName: 'prettyLogger');
  }
}

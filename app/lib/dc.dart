import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/behaviours/credential_converter.dart';
import 'package:score/features/user/behaviours/log_in_with_google.dart';
import 'package:score/features/user/behaviours/login_with_facebook.dart';
import 'package:score/features/user/bloc/log_in_bloc.dart' show LogInBloc;

import 'app_state/user_box.dart';

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
  LogInWithFacebook get logInWithFacebook => call();
  CredentialConverter get credentialConverter => call();

  FacebookAuth get facebookAuth => call();
  GoogleSignIn get googleSignIn => call();
  FirebaseAuth get firebaseAuth => call();
  Logger get logger => call();
  Logger get prettyLogger => call(instanceName: 'prettyLogger');
  UserBox get userBox => call();

  Future<void> init() async {
    registerSingleton(this);
    await Future.wait([
      registerBloc(),
      registerBehaviours(),
      registerData(),
    ]);
  }

  Future<void> registerBloc() async {
    registerFactory(
      () => LogInBloc(
        logInWithGoogle: logInWithGoogle,
        logInWithFacebook: logInWithFacebook,
      ),
    );
  }

  Future<void> registerBehaviours() async {
    registerLazySingleton(
      () => LogInWithFacebook(
        errorLogger: prettyLogger,
        facebookAuth: facebookAuth,
        firebaseAuth: firebaseAuth,
        credentialConverter: credentialConverter,
      ),
    );
    registerLazySingleton(
      () => LogInWithGoogle(
        errorLogger: prettyLogger,
        googleSignIn: googleSignIn,
        firebaseAuth: firebaseAuth,
        credentialConverter: credentialConverter,
      ),
    );
    registerLazySingleton(() => const CredentialConverter());
  }

  Future<void> registerData() async {
    registerSingleton(FirebaseAuth.instance);
    registerSingleton(FacebookAuth.i);
    registerLazySingleton(() => GoogleSignIn());
    registerLazySingleton(() => Logger(printer: SimplePrinter()));
    registerLazySingleton(
      () => Logger(printer: PrettyPrinter()),
      instanceName: 'prettyLogger',
    );
    registerLazySingleton(() => UserBox(googleSignIn: googleSignIn));
  }
}

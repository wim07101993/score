import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

import 'data/firebase/auth/auth_changes.dart';
import 'data/firebase/user/access_levels.dart';
import 'data/firebase/user/user.dart';

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
        Provider(create: (_) => getIt.firebaseAuth),
        ListenableProvider(create: (_) => getIt.accessLevelsChanges),
        ListenableProvider(create: (_) => getIt.userChanges),
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

  AccessLevelsChanges get accessLevelsChanges => call();
  AuthChanges get authChanges => call();
  CredentialConverter get credentialConverter => call();
  LogInWithGoogle get logInWithGoogle => call();
  LogInWithFacebook get logInWithFacebook => call();
  UserChanges get userChanges => call();

  FacebookAuth get facebookAuth => call();
  FirebaseAuth get firebaseAuth => call();
  FirebaseFirestore get firestore => call();
  GoogleSignIn get googleSignIn => call();
  Logger get logger => call();
  Logger get prettyLogger => call(instanceName: 'prettyLogger');
  UserRepository get userRepository => call();

  Future<void> init() async {
    registerSingleton(this);
    await registerData();
    await registerBehaviours();
    await registerBloc();
  }

  Future<void> registerBloc() async {
    registerFactory(
      () => LogInBloc(
        logInWithGoogle: logInWithGoogle,
        logInWithFacebook: logInWithFacebook,
        userChanges: userChanges,
        logger: logger,
      ),
    );
  }

  Future<void> registerBehaviours() async {
    registerFactory(
      () => AuthChanges(firebaseAuth: firebaseAuth, logger: logger),
    );
    registerFactory(
      () => AccessLevelsChanges(userRepository: userRepository),
    );
    registerFactory(
      () => UserChanges(userRepository: userRepository),
    );
    registerLazySingleton(() => const CredentialConverter());
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
  }

  Future<void> registerData() async {
    registerSingleton(FacebookAuth.i);
    registerSingleton(FirebaseAuth.instance);
    registerSingleton(FirebaseFirestore.instance);
    registerLazySingleton(() => GoogleSignIn());
    registerLazySingleton(() => Logger(printer: SimplePrinter()));
    registerLazySingleton(
      () => Logger(printer: PrettyPrinter()),
      instanceName: 'prettyLogger',
    );
    registerLazySingleton(
      () => UserRepository(authChanges: authChanges, firestore: firestore),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:score/shared/dependency_management/get_it_provider.dart';

@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final getIt = GetItProvider.of(context);
    return firebase.SignInScreen(providers: getIt());
  }
}

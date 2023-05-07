import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.getIt<FirebaseAuth>().signOut(),
      child: const Text('LogOut'),
    );
  }
}

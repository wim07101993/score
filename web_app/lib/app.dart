import 'package:flutter/material.dart';
import 'package:score/features/auth/models/user_value.dart';
import 'package:score/shared/dependency_management/get_it_provider.dart';
import 'package:score/shared/dependency_management/global_value.dart';
import 'package:score/shared/dependency_management/listenable_builder.dart';
import 'package:score/shared/router/app_router.dart';

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final getIt = GetItProvider.of(context);
    final router = getIt<AppRouter>();
    return ListenableBuilder(
      listenable: GlobalValueListenable(globalValue: getIt<UserValue>()),
      builder: (context, value, _) => MaterialApp.router(
          routerConfig: router.config(),
        ),
    );
  }
}

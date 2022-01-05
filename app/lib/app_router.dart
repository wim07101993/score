import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:score/user/widgets/login_screen.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: [
    AutoRoute(page: LoginScreen),
  ],
)
class AppRouter extends _$AppRouter {}

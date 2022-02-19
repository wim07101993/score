// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i6;

import '../features/new_score/widgets/create_new_score_screen.dart' as _i5;
import '../features/scores/widgets/scores_list_screen.dart' as _i4;
import '../features/user/widgets/profile_screen.dart' as _i3;
import '../features/user/widgets/sign_in_screen.dart' as _i1;

class AppRouter extends _i2.RootStackRouter {
  AppRouter([_i6.GlobalKey<_i6.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    SignInRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.SignInScreen());
    },
    AuthorizedRouter.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.EmptyRouterPage());
    },
    ProfileRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i3.ProfileScreen());
    },
    ScoresListRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.ScoresListScreen());
    },
    CreateNewScoreRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i5.CreateNewScoreScreen());
    }
  };

  @override
  List<_i2.RouteConfig> get routes => [
        _i2.RouteConfig(SignInRoute.name, path: '/sign-in-screen'),
        _i2.RouteConfig(AuthorizedRouter.name, path: 'authorized', children: [
          _i2.RouteConfig(ProfileRoute.name,
              path: 'profile-screen', parent: AuthorizedRouter.name),
          _i2.RouteConfig(ScoresListRoute.name,
              path: 'scores-list-screen', parent: AuthorizedRouter.name),
          _i2.RouteConfig(CreateNewScoreRoute.name,
              path: 'create-new-score-screen', parent: AuthorizedRouter.name)
        ])
      ];
}

/// generated route for
/// [_i1.SignInScreen]
class SignInRoute extends _i2.PageRouteInfo<void> {
  const SignInRoute() : super(SignInRoute.name, path: '/sign-in-screen');

  static const String name = 'SignInRoute';
}

/// generated route for
/// [_i2.EmptyRouterPage]
class AuthorizedRouter extends _i2.PageRouteInfo<void> {
  const AuthorizedRouter({List<_i2.PageRouteInfo>? children})
      : super(AuthorizedRouter.name,
            path: 'authorized', initialChildren: children);

  static const String name = 'AuthorizedRouter';
}

/// generated route for
/// [_i3.ProfileScreen]
class ProfileRoute extends _i2.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: 'profile-screen');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i4.ScoresListScreen]
class ScoresListRoute extends _i2.PageRouteInfo<void> {
  const ScoresListRoute()
      : super(ScoresListRoute.name, path: 'scores-list-screen');

  static const String name = 'ScoresListRoute';
}

/// generated route for
/// [_i5.CreateNewScoreScreen]
class CreateNewScoreRoute extends _i2.PageRouteInfo<void> {
  const CreateNewScoreRoute()
      : super(CreateNewScoreRoute.name, path: 'create-new-score-screen');

  static const String name = 'CreateNewScoreRoute';
}

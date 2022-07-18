// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/material.dart' as _i5;

import '../features/new_score/widgets/create_new_score_page.dart' as _i3;
import '../features/scores/widgets/scores_list_page.dart' as _i1;
import '../features/user/widgets/profile_page.dart' as _i2;

class AppRouter extends _i4.RootStackRouter {
  AppRouter([_i5.GlobalKey<_i5.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    ScoresListRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.ScoresListPage());
    },
    ProfileRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.ProfilePage());
    },
    CreateNewScoreRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i3.CreateNewScorePage());
    }
  };

  @override
  List<_i4.RouteConfig> get routes => [
        _i4.RouteConfig(ScoresListRoute.name, path: '/'),
        _i4.RouteConfig(ProfileRoute.name, path: '/profile-page'),
        _i4.RouteConfig(CreateNewScoreRoute.name,
            path: '/create-new-score-page')
      ];
}

/// generated route for
/// [_i1.ScoresListPage]
class ScoresListRoute extends _i4.PageRouteInfo<void> {
  const ScoresListRoute() : super(ScoresListRoute.name, path: '/');

  static const String name = 'ScoresListRoute';
}

/// generated route for
/// [_i2.ProfilePage]
class ProfileRoute extends _i4.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: '/profile-page');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i3.CreateNewScorePage]
class CreateNewScoreRoute extends _i4.PageRouteInfo<void> {
  const CreateNewScoreRoute()
      : super(CreateNewScoreRoute.name, path: '/create-new-score-page');

  static const String name = 'CreateNewScoreRoute';
}

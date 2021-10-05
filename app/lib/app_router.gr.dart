// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i2;

import 'features/home/widget/home_screen.dart' as _i4;
import 'features/user/widgets/log_in_screen.dart' as _i3;
import 'features/user/widgets/waiting_for_access_screen.dart' as _i5;

class AppRouter extends _i1.RootStackRouter {
  AppRouter([_i2.GlobalKey<_i2.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    LogInRoute.name: (routeData) => _i1.MaterialPageX<dynamic>(
        routeData: routeData,
        builder: (_) {
          return const _i3.LogInScreen();
        }),
    HomeRoute.name: (routeData) => _i1.MaterialPageX<dynamic>(
        routeData: routeData,
        builder: (_) {
          return const _i4.HomeScreen();
        }),
    WaitingForAccessRoute.name: (routeData) => _i1.MaterialPageX<dynamic>(
        routeData: routeData,
        builder: (_) {
          return const _i5.WaitingForAccessScreen();
        })
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(LogInRoute.name, path: '/log-in-screen'),
        _i1.RouteConfig(HomeRoute.name, path: '/home-screen'),
        _i1.RouteConfig(WaitingForAccessRoute.name,
            path: '/waiting-for-access-screen')
      ];
}

class LogInRoute extends _i1.PageRouteInfo {
  const LogInRoute() : super(name, path: '/log-in-screen');

  static const String name = 'LogInRoute';
}

class HomeRoute extends _i1.PageRouteInfo {
  const HomeRoute() : super(name, path: '/home-screen');

  static const String name = 'HomeRoute';
}

class WaitingForAccessRoute extends _i1.PageRouteInfo {
  const WaitingForAccessRoute()
      : super(name, path: '/waiting-for-access-screen');

  static const String name = 'WaitingForAccessRoute';
}

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

part of 'app_router.dart';

class _$AppRouter extends RootStackRouter {
  _$AppRouter([GlobalKey<NavigatorState>? navigatorKey]) : super(navigatorKey);

  @override
  final Map<String, PageFactory> pagesMap = {
    LogInRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const LogInScreen());
    },
    HomeRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const HomeScreen());
    },
    WaitingForAccessRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const WaitingForAccessScreen());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(LogInRoute.name, path: '/log-in-screen'),
        RouteConfig(HomeRoute.name, path: '/home-screen'),
        RouteConfig(WaitingForAccessRoute.name,
            path: '/waiting-for-access-screen')
      ];
}

/// generated route for [LogInScreen]
class LogInRoute extends PageRouteInfo<void> {
  const LogInRoute() : super(name, path: '/log-in-screen');

  static const String name = 'LogInRoute';
}

/// generated route for [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute() : super(name, path: '/home-screen');

  static const String name = 'HomeRoute';
}

/// generated route for [WaitingForAccessScreen]
class WaitingForAccessRoute extends PageRouteInfo<void> {
  const WaitingForAccessRoute()
      : super(name, path: '/waiting-for-access-screen');

  static const String name = 'WaitingForAccessRoute';
}

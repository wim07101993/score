// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:score/features/auth/widgets/log_in_screen.dart' as _i2;
import 'package:score/features/auth/widgets/user_info_screen.dart' as _i4;
import 'package:score/features/logging/widgets/logs_screen.dart' as _i3;
import 'package:score/features/scores/widgets/home_screen.dart' as _i1;

/// generated route for
/// [_i1.HomeScreen]
class HomeRoute extends _i5.PageRouteInfo<void> {
  const HomeRoute({List<_i5.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i1.HomeScreen();
    },
  );
}

/// generated route for
/// [_i2.LogInScreen]
class LogInRoute extends _i5.PageRouteInfo<void> {
  const LogInRoute({List<_i5.PageRouteInfo>? children})
    : super(LogInRoute.name, initialChildren: children);

  static const String name = 'LogInRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i2.LogInScreen();
    },
  );
}

/// generated route for
/// [_i3.LogsScreen]
class LogsRoute extends _i5.PageRouteInfo<void> {
  const LogsRoute({List<_i5.PageRouteInfo>? children})
    : super(LogsRoute.name, initialChildren: children);

  static const String name = 'LogsRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.LogsScreen();
    },
  );
}

/// generated route for
/// [_i4.UserInfoScreen]
class UserInfoRoute extends _i5.PageRouteInfo<void> {
  const UserInfoRoute({List<_i5.PageRouteInfo>? children})
    : super(UserInfoRoute.name, initialChildren: children);

  static const String name = 'UserInfoRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i4.UserInfoScreen();
    },
  );
}

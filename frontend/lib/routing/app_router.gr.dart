// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;
import 'package:score/features/auth/widgets/log_in_screen.dart' as _i1;
import 'package:score/features/auth/widgets/user_info_screen.dart' as _i4;
import 'package:score/features/logging/widgets/logs_screen.dart' as _i2;
import 'package:score/features/scores/widgets/score_list_screen.dart' as _i3;

/// generated route for
/// [_i1.LogInScreen]
class LogInRoute extends _i5.PageRouteInfo<LogInRouteArgs> {
  LogInRoute({
    _i6.Key? key,
    required dynamic Function(bool) redirect,
    List<_i5.PageRouteInfo>? children,
  }) : super(
          LogInRoute.name,
          args: LogInRouteArgs(
            key: key,
            redirect: redirect,
          ),
          initialChildren: children,
        );

  static const String name = 'LogInRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LogInRouteArgs>();
      return _i1.LogInScreen(
        key: args.key,
        redirect: args.redirect,
      );
    },
  );
}

class LogInRouteArgs {
  const LogInRouteArgs({
    this.key,
    required this.redirect,
  });

  final _i6.Key? key;

  final dynamic Function(bool) redirect;

  @override
  String toString() {
    return 'LogInRouteArgs{key: $key, redirect: $redirect}';
  }
}

/// generated route for
/// [_i2.LogsScreen]
class LogsRoute extends _i5.PageRouteInfo<void> {
  const LogsRoute({List<_i5.PageRouteInfo>? children})
      : super(
          LogsRoute.name,
          initialChildren: children,
        );

  static const String name = 'LogsRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i2.LogsScreen();
    },
  );
}

/// generated route for
/// [_i3.ScoreListScreen]
class ScoreListRoute extends _i5.PageRouteInfo<void> {
  const ScoreListRoute({List<_i5.PageRouteInfo>? children})
      : super(
          ScoreListRoute.name,
          initialChildren: children,
        );

  static const String name = 'ScoreListRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.ScoreListScreen();
    },
  );
}

/// generated route for
/// [_i4.UserInfoScreen]
class UserInfoRoute extends _i5.PageRouteInfo<void> {
  const UserInfoRoute({List<_i5.PageRouteInfo>? children})
      : super(
          UserInfoRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserInfoRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i4.UserInfoScreen();
    },
  );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/material.dart' as _i5;
import 'package:score/features/auth/widgets/log_in_screen.dart' as _i1;
import 'package:score/features/auth/widgets/user_info_screen.dart' as _i3;
import 'package:score/features/scores/widgets/score_list_screen.dart' as _i2;

/// generated route for
/// [_i1.LogInScreen]
class LogInRoute extends _i4.PageRouteInfo<LogInRouteArgs> {
  LogInRoute({
    _i5.Key? key,
    required dynamic Function(bool) redirect,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          LogInRoute.name,
          args: LogInRouteArgs(
            key: key,
            redirect: redirect,
          ),
          initialChildren: children,
        );

  static const String name = 'LogInRoute';

  static _i4.PageInfo page = _i4.PageInfo(
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

  final _i5.Key? key;

  final dynamic Function(bool) redirect;

  @override
  String toString() {
    return 'LogInRouteArgs{key: $key, redirect: $redirect}';
  }
}

/// generated route for
/// [_i2.ScoreListScreen]
class ScoreListRoute extends _i4.PageRouteInfo<void> {
  const ScoreListRoute({List<_i4.PageRouteInfo>? children})
      : super(
          ScoreListRoute.name,
          initialChildren: children,
        );

  static const String name = 'ScoreListRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i2.ScoreListScreen();
    },
  );
}

/// generated route for
/// [_i3.UserInfoScreen]
class UserInfoRoute extends _i4.PageRouteInfo<void> {
  const UserInfoRoute({List<_i4.PageRouteInfo>? children})
      : super(
          UserInfoRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserInfoRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i3.UserInfoScreen();
    },
  );
}

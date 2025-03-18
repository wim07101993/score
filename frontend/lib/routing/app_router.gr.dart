// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i7;
import 'package:flutter/material.dart' as _i8;
import 'package:score/features/auth/widgets/user_info_screen.dart' as _i6;
import 'package:score/features/logging/widgets/logs_screen.dart' as _i3;
import 'package:score/features/scores/widgets/home_screen.dart' as _i1;
import 'package:score/features/scores/widgets/home_screen/landing_screen.dart'
    as _i2;
import 'package:score/features/scores/widgets/home_screen/score_screen.dart'
    as _i5;
import 'package:score/features/scores/widgets/score_list_screen.dart' as _i4;

/// generated route for
/// [_i1.HomeScreen]
class HomeRoute extends _i7.PageRouteInfo<void> {
  const HomeRoute({List<_i7.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i1.HomeScreen();
    },
  );
}

/// generated route for
/// [_i2.LandingScreen]
class LandingRoute extends _i7.PageRouteInfo<void> {
  const LandingRoute({List<_i7.PageRouteInfo>? children})
    : super(LandingRoute.name, initialChildren: children);

  static const String name = 'LandingRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i2.LandingScreen();
    },
  );
}

/// generated route for
/// [_i3.LogsScreen]
class LogsRoute extends _i7.PageRouteInfo<void> {
  const LogsRoute({List<_i7.PageRouteInfo>? children})
    : super(LogsRoute.name, initialChildren: children);

  static const String name = 'LogsRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i3.LogsScreen();
    },
  );
}

/// generated route for
/// [_i4.ScoreListScreen]
class ScoreListRoute extends _i7.PageRouteInfo<void> {
  const ScoreListRoute({List<_i7.PageRouteInfo>? children})
    : super(ScoreListRoute.name, initialChildren: children);

  static const String name = 'ScoreListRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i4.ScoreListScreen();
    },
  );
}

/// generated route for
/// [_i5.ScoreScreen]
class ScoreRoute extends _i7.PageRouteInfo<ScoreRouteArgs> {
  ScoreRoute({
    _i8.Key? key,
    required String scoreId,
    List<_i7.PageRouteInfo>? children,
  }) : super(
         ScoreRoute.name,
         args: ScoreRouteArgs(key: key, scoreId: scoreId),
         rawPathParams: {'id': scoreId},
         initialChildren: children,
       );

  static const String name = 'ScoreRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ScoreRouteArgs>(
        orElse: () => ScoreRouteArgs(scoreId: pathParams.getString('id')),
      );
      return _i5.ScoreScreen(key: args.key, scoreId: args.scoreId);
    },
  );
}

class ScoreRouteArgs {
  const ScoreRouteArgs({this.key, required this.scoreId});

  final _i8.Key? key;

  final String scoreId;

  @override
  String toString() {
    return 'ScoreRouteArgs{key: $key, scoreId: $scoreId}';
  }
}

/// generated route for
/// [_i6.UserInfoScreen]
class UserInfoRoute extends _i7.PageRouteInfo<void> {
  const UserInfoRoute({List<_i7.PageRouteInfo>? children})
    : super(UserInfoRoute.name, initialChildren: children);

  static const String name = 'UserInfoRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i6.UserInfoScreen();
    },
  );
}

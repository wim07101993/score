// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;

import '../features/new_score/widgets/add_arrangement_form.dart' as _i5;
import '../features/new_score/widgets/create_new_score_page.dart' as _i3;
import '../features/new_score/widgets/new_score_form.dart' as _i4;
import '../features/scores/widgets/scores_list_page.dart' as _i1;
import '../features/user/widgets/profile_page.dart' as _i2;

class AppRouter extends _i6.RootStackRouter {
  AppRouter([_i7.GlobalKey<_i7.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    ScoresListRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.ScoresListPage());
    },
    ProfileRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.ProfilePage());
    },
    CreateNewScoreRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i3.CreateNewScorePage());
    },
    NewScoreForm.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.NewScoreForm());
    },
    AddArrangementForm.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i5.AddArrangementForm());
    }
  };

  @override
  List<_i6.RouteConfig> get routes => [
        _i6.RouteConfig(ScoresListRoute.name, path: '/'),
        _i6.RouteConfig(ProfileRoute.name, path: '/profile-page'),
        _i6.RouteConfig(CreateNewScoreRoute.name,
            path: '/create-new-score-page',
            children: [
              _i6.RouteConfig(NewScoreForm.name,
                  path: '', parent: CreateNewScoreRoute.name),
              _i6.RouteConfig(AddArrangementForm.name,
                  path: '', parent: CreateNewScoreRoute.name)
            ])
      ];
}

/// generated route for
/// [_i1.ScoresListPage]
class ScoresListRoute extends _i6.PageRouteInfo<void> {
  const ScoresListRoute() : super(ScoresListRoute.name, path: '/');

  static const String name = 'ScoresListRoute';
}

/// generated route for
/// [_i2.ProfilePage]
class ProfileRoute extends _i6.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: '/profile-page');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i3.CreateNewScorePage]
class CreateNewScoreRoute extends _i6.PageRouteInfo<void> {
  const CreateNewScoreRoute({List<_i6.PageRouteInfo>? children})
      : super(CreateNewScoreRoute.name,
            path: '/create-new-score-page', initialChildren: children);

  static const String name = 'CreateNewScoreRoute';
}

/// generated route for
/// [_i4.NewScoreForm]
class NewScoreForm extends _i6.PageRouteInfo<void> {
  const NewScoreForm() : super(NewScoreForm.name, path: '');

  static const String name = 'NewScoreForm';
}

/// generated route for
/// [_i5.AddArrangementForm]
class AddArrangementForm extends _i6.PageRouteInfo<void> {
  const AddArrangementForm() : super(AddArrangementForm.name, path: '');

  static const String name = 'AddArrangementForm';
}

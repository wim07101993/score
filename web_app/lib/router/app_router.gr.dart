// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i9;

import '../features/new_score/widgets/add_arrangement_form.dart' as _i7;
import '../features/new_score/widgets/create_new_score_page.dart' as _i5;
import '../features/new_score/widgets/new_score_form.dart' as _i6;
import '../features/scores/widgets/scores_list_page.dart' as _i3;
import '../features/user/widgets/profile_page.dart' as _i4;
import '../features/user/widgets/sign_in_screen.dart' as _i2;
import '../home/widgets/home.dart' as _i1;
import 'auth_guard.dart' as _i10;

class AppRouter extends _i8.RootStackRouter {
  AppRouter(
      {_i9.GlobalKey<_i9.NavigatorState>? navigatorKey,
      required this.authGuard})
      : super(navigatorKey);

  final _i10.AuthGuard authGuard;

  @override
  final Map<String, _i8.PageFactory> pagesMap = {
    Home.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.Home());
    },
    SignInScreen.name: (routeData) {
      final args = routeData.argsAs<SignInScreenArgs>();
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.SignInScreen(key: args.key, onSignedIn: args.onSignedIn));
    },
    ScoresListRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i3.ScoresListPage());
    },
    ProfileRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.ProfilePage());
    },
    CreateNewScoreRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i5.CreateNewScorePage());
    },
    NewScoreForm.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i6.NewScoreForm());
    },
    AddArrangementForm.name: (routeData) {
      final args = routeData.argsAs<AddArrangementFormArgs>();
      return _i8.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.AddArrangementForm(
              key: args.key, arrangementIndex: args.arrangementIndex));
    }
  };

  @override
  List<_i8.RouteConfig> get routes => [
        _i8.RouteConfig('/#redirect',
            path: '/', redirectTo: '', fullMatch: true),
        _i8.RouteConfig(Home.name, path: '', guards: [
          authGuard
        ], children: [
          _i8.RouteConfig('#redirect',
              path: '',
              parent: Home.name,
              redirectTo: 'scores-list',
              fullMatch: true),
          _i8.RouteConfig(ScoresListRoute.name,
              path: 'scores-list', parent: Home.name),
          _i8.RouteConfig(ProfileRoute.name,
              path: 'user/profile', parent: Home.name),
          _i8.RouteConfig(CreateNewScoreRoute.name,
              path: 'new-score/score-details',
              parent: Home.name,
              children: [
                _i8.RouteConfig('#redirect',
                    path: '',
                    parent: CreateNewScoreRoute.name,
                    redirectTo: 'new-score/score-details',
                    fullMatch: true),
                _i8.RouteConfig(NewScoreForm.name,
                    path: 'new-score/score-details',
                    parent: CreateNewScoreRoute.name),
                _i8.RouteConfig(AddArrangementForm.name,
                    path: 'new-score/arrangement/:arrangementIndex',
                    parent: CreateNewScoreRoute.name)
              ])
        ]),
        _i8.RouteConfig(SignInScreen.name, path: 'signin')
      ];
}

/// generated route for
/// [_i1.Home]
class Home extends _i8.PageRouteInfo<void> {
  const Home({List<_i8.PageRouteInfo>? children})
      : super(Home.name, path: '', initialChildren: children);

  static const String name = 'Home';
}

/// generated route for
/// [_i2.SignInScreen]
class SignInScreen extends _i8.PageRouteInfo<SignInScreenArgs> {
  SignInScreen({_i9.Key? key, required void Function() onSignedIn})
      : super(SignInScreen.name,
            path: 'signin',
            args: SignInScreenArgs(key: key, onSignedIn: onSignedIn));

  static const String name = 'SignInScreen';
}

class SignInScreenArgs {
  const SignInScreenArgs({this.key, required this.onSignedIn});

  final _i9.Key? key;

  final void Function() onSignedIn;

  @override
  String toString() {
    return 'SignInScreenArgs{key: $key, onSignedIn: $onSignedIn}';
  }
}

/// generated route for
/// [_i3.ScoresListPage]
class ScoresListRoute extends _i8.PageRouteInfo<void> {
  const ScoresListRoute() : super(ScoresListRoute.name, path: 'scores-list');

  static const String name = 'ScoresListRoute';
}

/// generated route for
/// [_i4.ProfilePage]
class ProfileRoute extends _i8.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: 'user/profile');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i5.CreateNewScorePage]
class CreateNewScoreRoute extends _i8.PageRouteInfo<void> {
  const CreateNewScoreRoute({List<_i8.PageRouteInfo>? children})
      : super(CreateNewScoreRoute.name,
            path: 'new-score/score-details', initialChildren: children);

  static const String name = 'CreateNewScoreRoute';
}

/// generated route for
/// [_i6.NewScoreForm]
class NewScoreForm extends _i8.PageRouteInfo<void> {
  const NewScoreForm()
      : super(NewScoreForm.name, path: 'new-score/score-details');

  static const String name = 'NewScoreForm';
}

/// generated route for
/// [_i7.AddArrangementForm]
class AddArrangementForm extends _i8.PageRouteInfo<AddArrangementFormArgs> {
  AddArrangementForm({_i9.Key? key, required int arrangementIndex})
      : super(AddArrangementForm.name,
            path: 'new-score/arrangement/:arrangementIndex',
            args: AddArrangementFormArgs(
                key: key, arrangementIndex: arrangementIndex));

  static const String name = 'AddArrangementForm';
}

class AddArrangementFormArgs {
  const AddArrangementFormArgs({this.key, required this.arrangementIndex});

  final _i9.Key? key;

  final int arrangementIndex;

  @override
  String toString() {
    return 'AddArrangementFormArgs{key: $key, arrangementIndex: $arrangementIndex}';
  }
}

import 'dart:async';
import 'dart:io';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:fox_logging/fox_logging.dart';
import 'package:http/http.dart';
import 'package:oidc/oidc.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authentication_exception.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:window_to_front/window_to_front.dart';

class const AuthenticateParams({
  final bool mayAskTheUser = true,
  final bool forceRefresh = false,
});

class Authenticate({
  super.monitor,
  required final OidcUserManager manager,
  required final OidcConfig config,
  required final Logger logger,
}) extends Behaviour<AuthenticateParams, UserInfo> {
  @override
  String get description => 'authenticating';

  @override
  Future<UserInfo> action(
    AuthenticateParams input,
    BehaviourTrack? track,
  ) async {
    try {
      final accessToken = await manager.getAccessToken(
        forceRefresh: input.forceRefresh,
      );
      final user = manager.currentUser;
      if (accessToken != null && user == null) {
        logger.warning('got access-token but no user info');
      } else if (accessToken != null && user != null) {
        return UserInfo(oidcUser: user, rolesKey: config.rolesKey);
      }
    } on OidcInteractionRequiredException {
      // nothing
    }

    if (!input.mayAskTheUser) {
      throw const SignInRequired();
    }

    final user = await manager.loginAuthorizationCodeFlow();
    final accessToken = user?.token.accessToken;
    if (user == null || accessToken == null) {
      throw const SignInCancelled();
    }

    if (kIsWeb) {
      return UserInfo(oidcUser: user, rolesKey: config.rolesKey);
    }

    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      await WindowToFront.activate();
    }
    return UserInfo(oidcUser: user, rolesKey: config.rolesKey);
  }

  @override
  Future<Exception> onCatchException(
    Exception exception,
    StackTrace stackTrace,
    BehaviourTrack? track,
  ) async {
    await super.onCatchException(exception, stackTrace, track);
    return switch (exception) {
      AuthenticationException() => exception,
      OidcException(extra: {'reason': 'window_closed'}) =>
        const SignInCancelled(),
      OidcException(errorResponse: OidcErrorResponse(error: 'access_denied')) =>
        const SignInCancelled(),
      OidcException(kind: OidcTokenRefreshFailureKind.transient) =>
        ProviderUnreachable(cause: exception),
      OidcException(
        internalException: TimeoutException() ||
            IOException() ||
            ClientException(),
      ) =>
        ProviderUnreachable(cause: exception),
      OidcException() => SignInFailed(cause: exception),
      TimeoutException() => ProviderUnreachable(cause: exception),
      IOException() => ProviderUnreachable(cause: exception),
      ClientException() => ProviderUnreachable(cause: exception),
      _ => exception,
    };
  }
}

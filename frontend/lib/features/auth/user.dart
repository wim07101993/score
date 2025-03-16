import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';

typedef UserListenable = ValueListenable<OidcUser?>;

extension UserExtensions on OidcUser {
  bool get isSessionExpired {
    final expiresIn = token.expiresIn;
    return expiresIn != null && expiresIn <= Duration.zero;
  }
}

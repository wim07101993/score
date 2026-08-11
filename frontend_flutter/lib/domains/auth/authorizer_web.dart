import 'package:web/web.dart' as web;

import '../../config.dart';
import 'authorizer.dart';

/// Signing in in a browser.
///
/// The page itself is what the provider sends the browser back to, so asking
/// for a code means leaving: the app is torn down, the provider does its half,
/// and the app starts again with the answer in its own address. Nothing here
/// waits for anything — [authorize] never returns, in the sense that matters.
class PlatformAuthorizer implements Authorizer {
  PlatformAuthorizer(this._config);

  final OidcConfig _config;

  @override
  Uri get redirectUri => _config.redirectUri;

  @override
  Future<Callback?> authorize(Uri authorizationUrl) async {
    _refuseIfServedFromSomewhereElse();

    web.window.location.href = authorizationUrl.toString();
    // The page is going away. Whatever a caller does with this answer, it will
    // not do it for long.
    return null;
  }

  /// Refuses to start a sign-in that cannot finish.
  ///
  /// The provider sends the browser to the address it was told to, and it will
  /// not be talked out of it: a redirect uri is compared exactly, port and all.
  /// So an app served from one port and registered under another sends the user
  /// away and leaves them on a page that is not there — with nothing on screen
  /// to say what went wrong, and this app no longer running to say it.
  ///
  /// Saying so before leaving is worth more than the sign-in that was never
  /// going to work.
  void _refuseIfServedFromSomewhereElse() {
    final here = Uri.parse(web.window.location.href).origin;
    final registered = redirectUri.origin;
    if (here == registered) {
      return;
    }

    throw StateError(
      'This app is being served from $here, but it is registered to be sent'
      ' back to $registered. A sign-in started here would end up at an address'
      ' nothing is listening on.\n'
      '\n'
      'Either serve it from $registered — `flutter run -d chrome --web-port='
      '${redirectUri.port}` — or change oidc.redirectUri in assets/config.json'
      ' to $here and register that with the provider.',
    );
  }

  @override
  Future<Callback?> pendingCallback() async {
    final query = Uri.parse(web.window.location.href).queryParameters;
    final code = query['code'];
    final state = query['state'];
    if (code == null || code.isEmpty || state == null) {
      return null;
    }
    return (code: code, state: state);
  }

  @override
  Future<void> clearCallback() async {
    // The code stays in the address bar otherwise, and a reload would spend it
    // a second time — which the provider refuses, correctly. Rewriting the
    // address rather than navigating to it keeps the app running.
    final here = Uri.parse(web.window.location.href);
    final without = here.replace(queryParameters: {}).toString();
    web.window.history.replaceState(
      null,
      '',
      without.endsWith('?') ? without.substring(0, without.length - 1) : without,
    );
  }
}

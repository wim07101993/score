import 'package:score/config.dart';
import 'package:score/features/auth/authorizer.dart';
import 'package:web/web.dart' as web;

/// Signing in in a browser.
///
/// The page itself is what the provider sends the browser back to, so asking
/// for a code means leaving: the app is torn down, the provider does its half,
/// and the app starts again with the answer in its own address. Nothing here
/// waits for anything — [authorize] never returns, in the sense that matters.
class PlatformAuthorizer implements Authorizer {
  PlatformAuthorizer(
    this._config,
  );

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
  Future<Callback?> pendingCallback() async =>
      readCallback(Uri.parse(web.window.location.href).queryParameters);

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

  /// The page the browser is on, without an answer a provider may have written
  /// onto it: a flow started on a page that already carries a spent code — an
  /// exchange that failed and fell through to asking again — is not sent back
  /// to that spelling of it.
  @override
  Uri? whereTheUserIs() {
    final here = Uri.parse(web.window.location.href);
    final query = {...here.queryParameters}
      ..remove('code')
      ..remove('state')
      ..remove('error')
      ..remove('error_description')
      ..remove('error_uri');
    return Uri(
      scheme: here.scheme,
      host: here.host,
      port: here.port,
      path: here.path,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  /// Only ever somewhere on this app. What is read back was written by this app
  /// and nobody else, but a redirect is worth being sure about.
  ///
  /// Replaced rather than pushed: the provider's redirect is already an entry
  /// in this tab's history, and going back to it is going back to a code that
  /// has been spent. And the app is started again at that address rather than
  /// navigated inside, because it has already started on the front page.
  @override
  Future<void> returnTo(Uri? where) async {
    if (where == null) return;
    final here = whereTheUserIs()!;
    if (where.origin != here.origin || _same(where, here)) return;
    web.window.location.replace(where.toString());
  }

  static bool _same(Uri a, Uri b) =>
      _pathOf(a) == _pathOf(b) && a.query == b.query;

  /// `https://x/` and `https://x` are the same front page.
  static String _pathOf(Uri uri) => uri.path.isEmpty ? '/' : uri.path;
}

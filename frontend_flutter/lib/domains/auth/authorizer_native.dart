import 'dart:io';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../config.dart';
import 'authorizer.dart';

/// Signing in on a device.
///
/// Nothing goes away here: the user does their half somewhere else, and the
/// answer comes back to the app while it is still running and still holding the
/// verifier it started with. Which is why there is nothing to pick up on the
/// next start.
///
/// *Where* it comes back to is not the same on a phone as on a desktop, and
/// that is the only thing this has to decide:
///
/// - A phone lets an app own a scheme, so the answer is addressed to the app
///   itself and the operating system delivers it.
/// - A desktop has no such thing. What it has is a port: the app listens on one
///   for as long as the sign-in takes, and the browser is sent back to it.
///
/// Either way the user types their password into their own browser and not into
/// a window this app drew. That is the whole point of doing it this way round —
/// an app that draws the login form is an app that could read what is typed
/// into it, which is why
/// [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252#section-8.12) says not to
/// and why providers increasingly refuse it.
class PlatformAuthorizer implements Authorizer {
  PlatformAuthorizer(this._config);

  final OidcConfig _config;

  /// Whether this is a machine where the answer has to come back to a port.
  ///
  /// macOS is not one of them: it hands a scheme to an app the way a phone
  /// does, and it has a sign-in window of the system's own to do it in.
  static final bool _listensOnAPort = Platform.isLinux || Platform.isWindows;

  @override
  Uri get redirectUri =>
      _listensOnAPort ? _config.desktopRedirectUri : _config.nativeRedirectUri;

  @override
  Future<Callback?> authorize(Uri authorizationUrl) async {
    final answer = await FlutterWebAuth2.authenticate(
      url: authorizationUrl.toString(),
      callbackUrlScheme: _callbackScheme,
      options: FlutterWebAuth2Options(
        // The user's own browser rather than a window drawn by this app. On a
        // desktop that is not merely the better of two ways: the other one
        // needs a webview built into the machine, and a machine without one
        // fails with nothing to show for it.
        useWebview: !_listensOnAPort,
        // Signed in for this app rather than for the browser it borrowed: the
        // window it opens keeps no cookie behind, so a shared laptop at a
        // rehearsal does not leave the last player signed in on it.
        preferEphemeral: true,
        landingPageHtml: _landingPage,
      ),
    );

    final query = Uri.parse(answer).queryParameters;
    final code = query['code'];
    final state = query['state'];
    if (code == null || code.isEmpty || state == null) {
      return null;
    }
    return (code: code, state: state);
  }

  /// What to listen on for the answer.
  ///
  /// A phone is called back on a scheme of its own; a desktop is called back on
  /// a port on this machine, and there the whole address is what has to be
  /// said.
  String get _callbackScheme {
    final uri = redirectUri;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return uri.scheme;
  }

  @override
  Future<Callback?> pendingCallback() async => null;

  @override
  Future<void> clearCallback() async {}
}

/// What the browser is left showing once it has handed the answer over.
///
/// The tab cannot close itself — a page may only close a window it opened
/// itself — so it says what has happened instead of sitting there blank while
/// the player wonders whether it worked.
const String _landingPage = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Signed in</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      color: #1c1b1f;
      background: #fdfcff;
    }
    main { text-align: center; max-width: 26rem; padding: 2rem; }
    h1 { font-size: 1.3rem; font-weight: 600; margin: 0 0 .5rem; }
    p { margin: 0; color: #45464f; }
    @media (prefers-color-scheme: dark) {
      body { color: #e5e1e6; background: #131316; }
      p { color: #c6c5d0; }
    }
  </style>
</head>
<body>
  <main>
    <h1>Signed in</h1>
    <p>You can close this tab and go back to Score.</p>
  </main>
</body>
</html>
''';

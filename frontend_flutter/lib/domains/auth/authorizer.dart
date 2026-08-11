import '../../config.dart';

import 'authorizer_native.dart'
    if (dart.library.js_interop) 'authorizer_web.dart';

/// What a code the user came back with looks like.
typedef Callback = ({String code, String state});

/// Sending the user to the provider and getting them back.
///
/// This is the one part of signing in that is not the same everywhere, and the
/// difference is not a detail: on the web the app *is* the page the provider
/// sends the browser back to, so it goes away and comes back having been
/// restarted, with the code sitting in its own address. On a device nothing
/// goes away — a window opens over the app, the code arrives through a scheme
/// the operating system knows belongs to it, and the app was running the whole
/// time.
///
/// Everything else about signing in — the verifier, the exchange, the refresh,
/// the roles — is the same on both, and lives in [OidcApi].
abstract class Authorizer {
  factory Authorizer(OidcConfig config) = PlatformAuthorizer;

  /// Which of the two addresses the provider should send the user back to.
  Uri get redirectUri;

  /// Sends the user to the provider.
  ///
  /// Hands back the code when it can be waited for, and `null` when the app is
  /// about to be navigated away from — in which case the answer will be waiting
  /// in [pendingCallback] the next time it starts.
  Future<Callback?> authorize(Uri authorizationUrl);

  /// A code the app was started with, if it was.
  Future<Callback?> pendingCallback();

  /// Takes the code out of wherever it was found, so that a reload is not read
  /// as a second sign-in with a code that has already been spent.
  Future<void> clearCallback();
}

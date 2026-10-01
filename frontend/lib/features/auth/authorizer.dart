import 'package:score/config.dart';
import 'package:score/features/auth/authorizer_native.dart'
    if (dart.library.js_interop) 'package:score/features/auth/authorizer_web.dart';

/// What a code the user came back with looks like.
typedef Callback = ({String code, String state});

/// Reads the provider's answer out of the query it was sent back with.
///
/// `null` when there is no answer in it at all. An answer that is not a code —
/// the user said no, or the provider would not ask them — is thrown, because
/// it is an answer: taking it for no answer is what sends the user straight
/// back to the provider to be refused again.
Callback? readCallback(Map<String, String> query) {
  final error = query['error'];
  if (error != null) {
    throw AuthorizationRefused(
      error,
      query['error_description'],
      query['state'],
    );
  }
  final code = query['code'];
  final state = query['state'];
  if (code == null || code.isEmpty || state == null) {
    return null;
  }
  return (code: code, state: state);
}

/// The provider sent the user back without a code.
class AuthorizationRefused implements Exception {
  const AuthorizationRefused(
    this.error, [
    this.description,
    this.state,
  ]);

  /// The OAuth error code, `access_denied` most often.
  final String error;
  final String? description;

  /// Which sign-in was refused, when the provider said.
  final String? state;

  @override
  String toString() => description == null || description!.isEmpty
      ? 'the provider did not sign you in: $error'
      : 'the provider did not sign you in: $error ($description)';
}

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
  factory Authorizer(
    OidcConfig config,
  ) = PlatformAuthorizer;

  /// Which of the two addresses the provider should send the user back to.
  Uri get redirectUri;

  /// Sends the user to the provider.
  ///
  /// Hands back the code when it can be waited for, and `null` when the app is
  /// about to be navigated away from — in which case the answer will be waiting
  /// in [pendingCallback] the next time it starts.
  Future<Callback?> authorize(Uri authorizationUrl);

  /// A code the app was started with, if it was. Throws
  /// [AuthorizationRefused] when it was started with a refusal instead.
  Future<Callback?> pendingCallback();

  /// Takes the code out of wherever it was found, so that a reload is not read
  /// as a second sign-in with a code that has already been spent.
  Future<void> clearCallback();

  /// Where the user is when a sign-in starts, so that finishing it can put
  /// them back there. `null` where the app is never left to sign in, and so
  /// never loses its place.
  Uri? whereTheUserIs();

  /// Puts the user back where a sign-in was started from, once it is done.
  ///
  /// The provider only ever sends the user back to the one address the app is
  /// registered with — the front page — so without this a link to a score
  /// opened in a tab with no token in it signs the player in and then shows
  /// them the list of every score instead.
  Future<void> returnTo(Uri? where);
}

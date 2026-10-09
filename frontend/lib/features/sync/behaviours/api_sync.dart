import 'package:logging/logging.dart';
import 'package:score/features/auth/behaviours/say_if_no_longer_signed_in.dart';
import 'package:score/features/auth/storage/auth_tokens.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/storage/api_exception.dart';

/// What every sync of a page's does around squaring one kind of thing with the
/// API: asking only when the API and the provider are there, saying so when
/// the sign-in no longer holds, and never throwing — a sync is asked for by a
/// page that is already drawn, and a sync that cannot happen is not a page that
/// should break.
class const ApiSync({
  required final Logger logger,
  required final OidcApi oidc,
  required final SayIfNoLongerSignedIn sayIfNoLongerSignedIn,
}) {
  Future<void> call({
    required String what,
    required Future<bool> Function() apiCanBeReached,
    required Future<void> Function() sync,
  }) async {
    // The provider too: a sync with no token to hand asks the player to sign
    // in, which is no use with a provider that is not there.
    if (!await apiCanBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      logger.fine(what);
      await sync();
      await sayIfNoLongerSignedIn.action(null);
    } on NotSignedIn catch (error) {
      // The player was asked, and said no: nothing went wrong.
      logger.info('not $what: $error');
    } catch (error, stackTrace) {
      logger.warning('failed $what', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }

  /// A token the API refused is spent, however long this device thinks it has
  /// left: revoked, or the session behind it ended somewhere else. It is
  /// forgotten, so that the next sync asks for a fresh one rather than sending
  /// the same one again until it runs out on its own.
  ///
  /// With no refresh token to get the next one with, the user has to sign in
  /// again — which is said, rather than done: a sync does not send anybody to
  /// the provider (see [OidcApi.getActiveAccessToken]), and one that did would
  /// go round for as long as the API refused what the provider handed out.
  Future<void> _forgetTokenIfRefused(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await oidc.forgetAccessToken();
    }
    await sayIfNoLongerSignedIn.action(null);
  }
}

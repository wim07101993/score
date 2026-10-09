import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/scores/storage/scores_api.dart';

/// What stands between this device and the server.
typedef Connection = ({
  /// Whether the server answers.
  bool server,

  /// Whether the provider that hands out its tokens answers.
  bool provider,

  /// Whether there is a token to send with, or something to get one with.
  bool signedIn,

  /// Whether what is on this device belongs to the account that is signed in:
  /// see [OidcApi.holdsTheDataOfTheSignedInUser].
  bool holdsTheirData,
});

/// Finds out what stands between this device and the server, for a page that
/// has to say why something did not sync. The server and the provider are
/// asked at the same time: each of them may take seconds to say it is not
/// there.
class CheckConnection({
  super.monitor,
  required final ScoresApi api,
  required final OidcApi oidc,
}) extends BehaviourWithoutInput<Connection> {
  @override
  String get description => 'checking the connection to the server';

  @override
  Future<Connection> action(BehaviourTrack? track) async {
    final reachable = await Future.wait([
      api.canBeReached(),
      oidc.canBeReached(),
    ]);
    return (
      server: reachable[0],
      provider: reachable[1],
      signedIn: await oidc.holdsAToken(),
      holdsTheirData: await oidc.holdsTheDataOfTheSignedInUser(),
    );
  }
}

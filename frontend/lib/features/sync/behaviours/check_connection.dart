import 'package:behaviour/behaviour.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';
import 'package:score/config.dart';
import 'package:score/features/scores/storage/scores_api.dart';

/// What stands between this device and the server.
typedef Connection = ({
  /// Whether the server answers.
  bool server,

  /// Whether the provider that hands out its tokens answers.
  bool provider,

  /// Whether there is a token to send with, or something to get one with.
  bool signedIn,
});

class CheckConnection({
  super.monitor,
  required final ScoresApi api,
  required final OidcUserManager manager,
  required final OidcConfig config,
  required final http.Client client,
}) extends BehaviourWithoutInput<Connection> {
  @override
  String get description => 'checking the connection to the server';

  @override
  Future<Connection> action(BehaviourTrack? track) async {
    final reachable = await Future.wait([
      api.canBeReached(),
      _providerCanBeReached(),
    ]);
    return (
      server: reachable[0],
      provider: reachable[1],
      signedIn: manager.currentUser != null,
    );
  }

  Future<bool> _providerCanBeReached() async {
    try {
      final response = await client
          .get(config.healthzEndpoint)
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}

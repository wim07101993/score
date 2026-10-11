import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:http/http.dart';
import 'package:score/config.dart';

class CanConnectToOidcProvider({
  required super.monitor,
  required final Client httpClient,
  required final OidcConfig config,
}) extends BehaviourWithoutInput<bool> {
  @override
  Future<bool> action(BehaviourTrack? track) {
    return httpClient
        .get(config.healthzEndpoint)
        .timeout(const Duration(seconds: 5))
        .then((response) => response.statusCode < 400);
  }
}

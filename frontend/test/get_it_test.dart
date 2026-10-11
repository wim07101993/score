import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/auth/behaviours/can_connect_to_api.dart';
import 'package:score/features/auth/behaviours/can_connect_to_oidc_provider.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/sync/behaviours/check_connection.dart';
import 'package:score/features/sync/behaviours/update_collections.dart';
import 'package:score/features/sync/behaviours/update_scores.dart';
import 'package:score/features/sync/behaviours/update_sets.dart';

import 'test_get_it.dart';

void main() {
  setUp(() => GetIt.I.registerForTesting());
  tearDown(() => GetIt.I.popScope());

  test('what the pages ask for can be built once the app has started', () {
    expect(GetIt.I.get<SyncScores>, returnsNormally);
    expect(GetIt.I.get<UpdateScores>, returnsNormally);
    expect(GetIt.I.get<UpdateSets>, returnsNormally);
    expect(GetIt.I.get<UpdateCollections>, returnsNormally);
    expect(GetIt.I.get<CheckConnection>, returnsNormally);
    expect(GetIt.I.get<Authenticate>, returnsNormally);
    expect(GetIt.I.get<CanConnectToApi>, returnsNormally);
    expect(GetIt.I.get<CanConnectToOidcProvider>, returnsNormally);
  });
}

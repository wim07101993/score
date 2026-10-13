import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/auth/behaviours/can_connect_to_api.dart';
import 'package:score/features/auth/behaviours/can_connect_to_oidc_provider.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sync/sync_engine.dart';

import 'test_get_it.dart';

void main() {
  setUp(() => GetIt.I.registerForTesting());
  tearDown(() => GetIt.I.popScope());

  test('what the pages ask for can be built once the app has started', () {
    expect(GetIt.I.get<SyncScores>, returnsNormally);
    expect(GetIt.I.get<SyncSets>, returnsNormally);
    expect(GetIt.I.get<SyncCollections>, returnsNormally);
    expect(GetIt.I.get<SyncEngine>, returnsNormally);
    expect(GetIt.I.get<Authenticate>, returnsNormally);
    expect(GetIt.I.get<CanConnectToApi>, returnsNormally);
    expect(GetIt.I.get<CanConnectToOidcProvider>, returnsNormally);
  });
}

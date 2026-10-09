import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/sets/behaviours/delete_set.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';

import '../../test_api.dart';
import '../../test_stores.dart';

/// What the pages are drawn from: the sets as the store has them, followed
/// rather than asked for, and why what is owed about them was not sent.

final _config = OidcConfig(
  clientId: 'test',
  issuer: Uri.parse('http://nowhere'),
  redirectUri: Uri.parse('http://localhost/'),
  nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
  desktopRedirectUri: Uri.parse('http://localhost:7005/'),
  authorizationEndpoint: Uri.parse('http://nowhere/authorize'),
  tokenEndpoint: Uri.parse('http://nowhere/token'),
  userInfoEndpoint: Uri.parse('http://nowhere/userinfo'),
  healthzEndpoint: Uri.parse('http://nowhere/healthz'),
  rolesKey: 'roles',
);

/// An API that is not there.
class _OfflineApi() extends SetsApi {
  this : super(clientFactory: testClientFactory());

  @override
  Future<bool> canBeReached() async => false;
}

/// Lets what was just written reach whoever follows the store.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late Stores store;
  late SetsEngine engine;
  late SetsNotifier sets;

  setUp(() async {
    store = await Stores.inMemory();
    engine = SetsEngine(
      logger: Logger('test'),
      adapter: SetsAdapter(
        logger: Logger('test'),
        store: store.sets,
        holds: store.holds,
        api: _OfflineApi(),
      ),
      oidc: OidcApi(config: _config, store: store.auth),
    );
    await engine.init();
    sets = SetsNotifier(store: store.sets, holds: store.holds, engine: engine);
    addTearDown(sets.dispose);
    await sets.ready;
  });

  test('a set that is saved is on the page, without the page asking', () async {
    var told = 0;
    sets.addListener(() => told++);

    final saved = await SaveSet(engine: engine)
        .action(const SaveSetParams(title: 'Friday'), null);
    await _settle();

    expect(told, greaterThan(0));
    expect(sets.getSet(saved.id)?.title, 'Friday');
    expect(sets.sets.map((set) => set.id), [saved.id]);
    expect(sets.hasPendingChanges, isTrue, reason: 'the server is not there');
  });

  test('a deleted set is no longer one anybody has', () async {
    final saved = await SaveSet(engine: engine)
        .action(const SaveSetParams(title: 'Friday'), null);
    await DeleteSet(engine: engine).action(saved.id, null);
    await _settle();

    expect(sets.getSet(saved.id), isNull);
    expect(sets.sets, isEmpty);
    expect(
      sets.hasPendingChanges,
      isTrue,
      reason: 'the deletion is still owed to the server',
    );
  });

  test('why it was not sent is said for as long as it is owed', () async {
    final saved = await SaveSet(engine: engine)
        .action(const SaveSetParams(title: 'Friday'), null);
    await _settle();

    expect(sets.whyNotSynced(saved.id)?.hold, SyncHold.unreachable);
  });

  test(
    'what was not sent in an earlier run has not been tried in this one',
    () async {
      final saved = await SaveSet(engine: engine)
          .action(const SaveSetParams(title: 'Friday'), null);

      // The app, started again over the same store.
      final restarted = SetsEngine(
        logger: Logger('test'),
        adapter: SetsAdapter(
          logger: Logger('test'),
          store: store.sets,
          holds: store.holds,
          api: _OfflineApi(),
        ),
        oidc: OidcApi(config: _config, store: store.auth),
      );
      await restarted.init();
      await _settle();

      expect(sets.getSet(saved.id), isNotNull);
      expect(sets.whyNotSynced(saved.id), isNull);
    },
  );
}

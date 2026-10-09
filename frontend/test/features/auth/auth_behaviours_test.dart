import 'package:behaviour/behaviour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/behaviours/say_if_no_longer_signed_in.dart';
import 'package:score/features/auth/behaviours/sign_out.dart';
import 'package:score/features/auth/behaviours/sign_outs.dart';
import 'package:score/features/auth/behaviours/update_auth.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/behaviours/forget_collections.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/sets/behaviours/forget_sets.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/storage/sets_api.dart';

import '../../test_api.dart';
import '../../test_stores.dart';

/// Who the device is for, kept where every page reads it from.
///
/// Every page decides what to show from the roles the provider sent, so what
/// the behaviours that ask about the user leave behind — who it is, whether
/// that is this device's copy, what went wrong — is what the whole app shows.

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

const _player = UserInfo(
  subject: 'player',
  roles: {'score_viewer': <String, dynamic>{}},
);

/// A provider that is there or not, and that says the user is [answer].
class _Provider({
  required super.store,
  final bool reachable = true,
  final UserInfo? answer,
  final bool token = true,
}) extends OidcApi {
  this : super(config: _config);

  @override
  Future<bool> canBeReached() async => reachable;

  @override
  Future<UserInfo?> getUserInfo() async {
    await keepUserInfo(answer);
    return answer;
  }

  @override
  Future<bool> holdsAToken() async => token;

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async =>
      token ? 'a-token' : null;
}

/// The behaviours that ask about the user, over [oidc] and [store].
class _Auth({
  required final Stores store,
  required final OidcApi oidc,
}) {
  late final authStore = AuthStore(store: store.auth);
  late final signOuts = SignOuts();
  late final sets = SetsEngine(
    logger: Logger('test'),
    adapter: SetsAdapter(
      logger: Logger('test'),
      store: store.sets,
      holds: store.holds,
      api: SetsApi(clientFactory: testClientFactory()),
    ),
    oidc: oidc,
  );
  late final collections = CollectionsEngine(
    logger: Logger('test'),
    adapter: CollectionsAdapter(
      logger: Logger('test'),
      store: store.collections,
      holds: store.holds,
      api: CollectionsApi(clientFactory: testClientFactory()),
    ),
    oidc: oidc,
  );

  UpdateAuth get updateAuth => UpdateAuth(
    logger: Logger('test'),
    oidc: oidc,
    authStore: authStore,
    signOuts: signOuts,
    forgetSets: ForgetSets(engine: sets),
    forgetCollections: ForgetCollections(engine: collections),
  );

  SignOut get signOut => SignOut(
    oidc: oidc,
    authStore: authStore,
    signOuts: signOuts,
    forgetSets: ForgetSets(engine: sets),
    forgetCollections: ForgetCollections(engine: collections),
  );

  /// What the pages read, once it holds what the store holds.
  Future<AuthNotifier> notifier() async {
    final notifier = AuthNotifier(oidc: oidc, authStore: authStore);
    addTearDown(notifier.dispose);
    await notifier.ready;
    return notifier;
  }
}

/// Lets what was just written reach whoever follows the store.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late Stores store;

  setUp(() async => store = await Stores.inMemory());

  test('who the provider says it is, is who every page is drawn for', () async {
    final auth = _Auth(
      store: store,
      oidc: _Provider(store: store.auth, answer: _player),
    );
    final notifier = await auth.notifier();

    await auth.updateAuth.action(const UpdateAuthParams(), null);
    await _settle();

    expect(notifier.user?.subject, 'player');
    expect(notifier.userIsFromThisDevice, isFalse);
    expect(notifier.authProblem, isNull);
  });

  test(
    'a provider that cannot be reached is the kept copy, said to be so',
    () async {
      final oidc = _Provider(store: store.auth, reachable: false);
      await oidc.keepUserInfo(_player);
      final auth = _Auth(store: store, oidc: oidc);
      final notifier = await auth.notifier();

      final user = await auth.updateAuth.action(const UpdateAuthParams(), null);
      await _settle();

      expect(user?.subject, 'player');
      expect(notifier.user?.subject, 'player');
      expect(
        notifier.userIsFromThisDevice,
        isTrue,
        reason: 'these were the roles the last time it could ask',
      );
    },
  );

  test(
    'signing out forgets the user and their sets, and every page hears it',
    () async {
      final oidc = _Provider(store: store.auth, answer: _player);
      final auth = _Auth(store: store, oidc: oidc);
      await auth.sets.init();
      await auth.collections.init();
      await auth.updateAuth.action(const UpdateAuthParams(), null);
      await SaveSet(engine: auth.sets)
          .action(const SaveSetParams(title: 'Friday'), null);
      final notifier = await auth.notifier();

      await auth.signOut.action(null);
      await _settle();

      expect(notifier.user, isNull);
      expect(await store.sets.getAll(), isEmpty);
    },
  );

  test('a sync that loses the sign-in says so on every page', () async {
    final oidc = _Provider(store: store.auth, token: false);
    await oidc.keepUserInfo(_player);
    final auth = _Auth(store: store, oidc: oidc);
    final notifier = await auth.notifier();

    await SayIfNoLongerSignedIn(
      oidc: oidc,
      authStore: auth.authStore,
    ).action(null);
    await _settle();

    expect(notifier.authProblem, contains('sign in again'));
  });

  test('what goes wrong is handed back rather than thrown', () async {
    final auth = _Auth(
      store: store,
      oidc: _Provider(store: store.auth),
    );
    await store.databases.data.close();

    expect(
      await auth.signOut(),
      isA<Failed<void>>(),
    );
  });
}

import 'package:score/features/auth/storage/auth_key_value_store.dart';

/// What this device knows about how it came to know who its user is: whether
/// that is the copy it kept or what the provider just said, and what went wrong
/// the last time it asked. Who the user is, is kept by [OidcApi].
class const AuthStore({
  required final AuthKeyValueStore store,
}) {
  static const _fromThisDeviceKey = 'auth_user_from_this_device';
  static const _problemKey = 'auth_problem';

  Future<void> keepFromThisDevice({required bool fromThisDevice}) =>
      store.write(_fromThisDeviceKey, fromThisDevice ? 'true' : null);

  Stream<bool> watchFromThisDevice() =>
      store.watch(_fromThisDeviceKey).map((stored) => stored != null);

  /// What went wrong, as it is said to the player, or null when nothing did.
  Future<void> keepProblem(Object? problem) =>
      store.write(_problemKey, problem?.toString());

  Future<String?> readProblem() => store.read(_problemKey);

  Stream<String?> watchProblem() => store.watch(_problemKey);
}

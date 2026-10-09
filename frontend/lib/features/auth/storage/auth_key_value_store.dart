import 'package:score/storage/key_value_store.dart';

/// What this device keeps about signing in: the tokens, who the user is, and
/// a sign-in that is under way.
class AuthKeyValueStore({
  required super.database,
}) extends KeyValueStore {
  this : super(name: 'auth');
}

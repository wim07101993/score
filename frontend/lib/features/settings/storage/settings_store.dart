import 'package:score/storage/key_value_store.dart';

/// What this device has been told to prefer. Never sent anywhere: see
/// `settings/models.dart`.
class SettingsStore({
  required super.database,
}) extends KeyValueStore {
  this : super(name: 'settings');
}

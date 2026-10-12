import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/observability/storage/logs_store.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';
import 'package:score/storage/databases.dart';

/// Every feature's store, over databases that live in memory: what a test
/// keeps things in.
class Stores._({
  required final Databases databases,
}) {
  static Future<Stores> inMemory() async =>
      Stores._(databases: await Databases.inMemory());

  late final scores = ScoresDatabase(client: databases.data);
  late final documents = InMemoryScoreDocuments();
  late final sets = SetsDatabase(client: databases.data);
  late final collections = CollectionsDatabase(client: databases.data);
  late final syncDates = SyncDatesStore(client: databases.data);
  late final settings = SettingsStore(database: databases.data);
  late final logs = LogsStore(database: databases.data);
}

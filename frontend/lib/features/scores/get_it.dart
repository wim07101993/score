import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:get_it/get_it.dart';

const String scoreDatabase = 'score';
const String scoresCollection = 'scores';

void registerScoreDependencies() {
  GetIt.I.registerLazySingletonAsync<Database>(
    () async {
      await CouchbaseLiteFlutter.init();
      return Database.openAsync(scoreDatabase);
    },
    dispose: (database) => database.close(),
  );

  GetIt.I.registerLazySingletonAsync<Collection>(
    () async {
      final database = await GetIt.I.getAsync<Database>();
      return database.createCollection(scoresCollection);
    },
    instanceName: scoresCollection,
  );
}

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:get_it/get_it.dart';

const String scoreDatabase = 'score';
const String scoresCollection = 'scores';
const String scoresCollectionInstance = 'scores-collection';

void registerScoreDependencies() {
  GetIt.I.registerLazySingletonAsync<Database>(
    () async {
      await CouchbaseLiteDart.init(edition: Edition.community);
      return Database.openAsync(scoreDatabase);
    },
    dispose: (database) => database.close(),
  );

  GetIt.I.registerLazySingletonAsync<Collection>(
    () async {
      final database = await GetIt.I.getAsync<Database>();
      return database.createCollection(scoresCollection);
    },
    instanceName: scoresCollectionInstance,
  );
}

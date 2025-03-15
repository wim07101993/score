import 'dart:developer';

import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:score/features/logging/db_extensions.dart';
import 'package:score/features/scores/db_extensions.dart';

void registerLibsqlDependencies() {
  GetIt.I.registerLazySingletonAsync<LibsqlClient>(
    () async {
      final dir = await getApplicationCacheDirectory();
      final path = '${dir.path}/scores.db';
      log('database-path: $path');
      final client = LibsqlClient(path);
      await client.connect();
      await client.applyLogMigrations();
      await client.applyScoreMigrations();
      return client;
    },
    dispose: (database) => database.dispose(),
  );
}

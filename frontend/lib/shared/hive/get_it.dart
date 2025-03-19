import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:score/features/logging/db_extensions.dart';
import 'package:score/shared/hive/hive_registrar.g.dart';
import 'package:score/shared/hive/stack_trace_type_adapter.dart';

void registerHive() {
  GetIt.I.registerLazySingletonAsync(() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(const NullableStackTraceTypeAdapter())
      ..registerAdapter(const LogRecordAdapter())
      ..registerAdapter(const LogLevelAdapter())
      ..registerAdapters();
    return Hive;
  });
}

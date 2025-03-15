import 'dart:async';

import 'package:libsql_dart/libsql_dart.dart';

extension DbExtensions on LibsqlClient {
  Stream<Map<String, dynamic>> stream(
    String sql, {
    int pageSize = 100,
    Map<String, dynamic>? named,
    List<dynamic>? positional,
  }) async* {
    var offset = 0;
    var buffer = query(
      '$sql LIMIT $pageSize',
      named: named,
      positional: positional,
    );

    while (true) {
      final resultsFuture = buffer;

      offset += pageSize;
      buffer = query(
        '$sql LIMIT $pageSize OFFSET $offset',
        named: named,
        positional: positional,
      );

      final results = await resultsFuture;
      if (results.isEmpty) {
        return;
      }

      for (final item in results) {
        yield item;
      }
    }
  }
}

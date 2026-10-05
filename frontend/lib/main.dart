import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:score/app.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/get_it.dart';

void main() {
  runZonedGuarded(
    () {
      GetIt.I.registerDependencies();
      run();
    },
    (error, stackTrace) {
      GetIt.I.logger('platform-error').severe('$error', error, stackTrace);
    },
  );
}

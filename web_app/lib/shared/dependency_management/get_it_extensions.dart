import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';

extension DependencyManagementGetItExtensions on GetIt {
  Logger logger<T>([String? loggerName]) {
    return get<Logger>(param1: loggerName ?? T.runtimeType.toString());
  }

  Logger? tryGetLogger<T>([String? loggerName]) {
    return isRegistered<Logger>() ? logger<T>(loggerName) : null;
  }
}

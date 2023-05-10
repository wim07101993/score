import 'package:flutter/widgets.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';
import 'package:score/shared/dependency_management/get_it_extensions.dart';

extension LoggingWidgetExtensions<T extends StatefulWidget> on State<T> {
  Logger get logger => context.getIt.logger(runtimeType.toString());
}

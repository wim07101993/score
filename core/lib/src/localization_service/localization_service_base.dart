import 'package:flutter/widgets.dart';

abstract class LocalizationServiceBase {
  String localizeExceptionMessage(BuildContext context, Exception exception);
}

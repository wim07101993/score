import 'package:flutter/widgets.dart';
import 'package:score/globals.dart';

class PermissionDeniedException implements Exception {
  const PermissionDeniedException();

  String errorMessage(BuildContext context) {
    return S.of(context)!.permissionsDeniedErrorMessage;
  }
}

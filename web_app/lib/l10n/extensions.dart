import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:score/globals.dart';

extension FutureExceptionOrExtensions<T> on Future<ExceptionOr<T>> {
  Future<void> handleException(
    BuildContext context, [
    Future<void> Function(Exception exception)? action,
  ]) {
    final s = S.of(context)!;
    if (action != null) {
      return thenWhen(action, (value) {});
    }
    return thenWhen(
      (exception) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translateException(s, exception))),
      ),
      (value) {},
    );
  }
}

String translateException(S s, Exception exception) {
  return s.genericErrorMessage;
}

import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class StreamNotifier<T>({
  required T initial,
}) extends ValueNotifier<T> {
  this : super(initial);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<Future<void>> _firsts = [];

  Future<void> get ready => Future.wait(_firsts);

  @protected
  void follow(Stream<T> stream) {
    final first = Completer<void>();
    _firsts.add(first.future);
    _subscriptions.add(
      stream.listen(
        (v) {
          value = v;
          if (!first.isCompleted) {
            first.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!first.isCompleted) {
            first.completeError(error, stackTrace);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}

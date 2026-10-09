import 'dart:async';

import 'package:flutter/foundation.dart';

/// What the store holds, kept up to date for whoever draws it.
///
/// A page never asks whoever wrote to the store what changed: it follows the
/// store, through one of these, and is redrawn when the store is written to —
/// by a behaviour of this tab, another tab of the web app, or a sync. That is
/// the only way state reaches a widget.
///
/// It starts following when it is made, which GetIt does the first time it is
/// asked for one; [ready] is done once every stream it follows has said what it
/// holds, so that nothing is drawn from a value that was never in the store.
abstract class StoreNotifier<T>({
  required T initial,
}) extends ValueNotifier<T> {
  this : super(initial);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<Future<void>> _firsts = [];

  /// Done once every stream this follows has handed over its first value.
  Future<void> get ready => Future.wait(_firsts);

  /// Follows [stream] for as long as this lives, handing each value to [take].
  @protected
  void follow<S>(Stream<S> stream, void Function(S value) take) {
    final first = Completer<void>();
    _firsts.add(first.future);
    _subscriptions.add(
      stream.listen(
        (value) {
          take(value);
          if (!first.isCompleted) first.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!first.isCompleted) first.completeError(error, stackTrace);
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

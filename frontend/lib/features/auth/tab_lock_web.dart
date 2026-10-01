import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Future<T> platformUnderTabLock<T>(
  String name,
  Future<T> Function() body,
) async {
  // Only in a secure context, and not in every browser the app still opens in.
  if (!web.window.navigator.has('locks')) {
    return body();
  }

  final done = Completer<T>();
  JSPromise<JSAny?> granted(web.Lock? _) => () async {
        try {
          done.complete(await body());
        } catch (error, stackTrace) {
          done.completeError(error, stackTrace);
        }
      }()
          .toJS;
  try {
    await web.window.navigator.locks.request(name, granted.toJS).toDart;
  } catch (_) {
    // The lock itself failing is no reason not to do what it was for; what
    // [body] threw is in [done].
    if (!done.isCompleted) return body();
  }
  return done.future;
}

import 'package:score/features/auth/tab_lock_native.dart'
    if (dart.library.js_interop) 'package:score/features/auth/tab_lock_web.dart';

/// Runs [body] while no other tab of the app runs anything under [name].
///
/// Only the web has tabs: each is a program of its own over the one store, and
/// two of them spending the same refresh token at once is a race one of them
/// loses. Everywhere else, and in a browser without the Web Locks API, [body]
/// just runs.
Future<T> underTabLock<T>(String name, Future<T> Function() body) =>
    platformUnderTabLock(name, body);

import 'dart:js_interop';
// Reaching a property by its name, which is what this has to do: the thing
// being replaced is a browser global, not something with a Dart binding.
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sembast_web/sembast_web.dart';

/// Where a browser keeps what this app has, which is IndexedDB — the same place
/// the app kept it before it was written in Dart, so a player who had scores on
/// their device before still has room for them now.
Future<Database> openDatabase(String name) {
  _keepOneRevisionChannel();
  return databaseFactoryWeb.openDatabase(name);
}

/// The channel `sembast_web` tells other tabs about writes on.
const _revisionChannel = 'sembast_web_storage_revision';

/// Where the one channel is kept, somewhere a hot restart cannot reach.
const _kept = '__scoreSembastRevisionChannel';

/// Where the browser's own constructor is kept, for the same reason.
const _nativeConstructor = '__scoreNativeBroadcastChannel';

/// Hands out a single revision channel per page, rather than one per restart.
///
/// This exists for one console error, and only in development:
///
///     TypeError: Instance of 'LegacyJavaScriptObject':
///     type 'LegacyJavaScriptObject' is not a subtype of type
///     'JdbNotificationRevision'
///
/// `sembast_web` keeps a `BroadcastChannel` in a top-level variable and hangs a
/// listener off it, and cancels that listener — the only thing that detaches it
/// — when the last database closes. A hot restart closes nothing. It throws the
/// Dart program away and starts a new one, and the new one builds a *second*
/// channel on the same name while the browser goes on holding the first, whose
/// listener is a closure belonging to a program that no longer exists. The next
/// write is delivered to both. The live one handles it; the dead one tries to
/// hand a value to a stream whose element type now means a class from the new
/// program, and the cast fails. One more of them survives every restart, which
/// is why the same error is printed twice, then four times, then six.
///
/// So the second channel is never built. Asked for this one name, the browser
/// hands back the channel it handed out before, and `sembast_web` — which sets
/// `onmessage` on whatever it is given — replaces the dead listener with its own
/// rather than joining it. Nothing is left listening from before, and there is
/// nothing to leak: the channel is the same object it always was.
///
/// Only this one name is caught, so nothing else that speaks between tabs is
/// affected; and only in debug, because the whole problem is hot restart, which
/// is a thing that only happens while somebody is working on the app. A page
/// that has been loaded once has one program and one channel anyway.
void _keepOneRevisionChannel() {
  if (!kDebugMode || globalContext.has(_nativeConstructor)) {
    return;
  }

  final native = globalContext['BroadcastChannel'] as JSFunction;
  globalContext[_nativeConstructor] = native;

  JSObject channelFor(JSString name) {
    if (name.toDart != _revisionChannel) {
      return native.callAsConstructor<JSObject>(name);
    }
    // `globalThis` outlives the program that put it there, which is the whole
    // point: this is where the channel is found again after a restart.
    final kept = globalContext[_kept];
    if (kept.isA<JSObject>()) {
      return kept as JSObject;
    }
    final channel = native.callAsConstructor<JSObject>(name);
    globalContext[_kept] = channel;
    return channel;
  }

  globalContext['BroadcastChannel'] = channelFor.toJS;
}

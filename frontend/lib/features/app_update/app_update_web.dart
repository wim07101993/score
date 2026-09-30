import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

final ValueNotifier<bool> _ready = () {
  // Set by the bootstrap, which may have seen the new version take over before
  // this was first asked.
  final ready = ValueNotifier(
    web.window.getProperty<JSBoolean?>('scoreAppUpdated'.toJS)?.toDart ??
        false,
  );
  web.window.addEventListener(
    'score-app-updated',
    ((web.Event _) => ready.value = true).toJS,
  );
  return ready;
}();

ValueListenable<bool> get platformNewVersionReady => _ready;

void platformStartOnTheNewVersion() => web.window.location.reload();

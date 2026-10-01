import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

VoidCallback platformWarnBeforeLeavingThePage() {
  final listener = ((web.Event event) {
    // Asking is all a page may do; the browser words the question itself.
    event.preventDefault();
    (event as web.BeforeUnloadEvent).returnValue = '';
  }).toJS;
  web.window.addEventListener('beforeunload', listener);
  return () => web.window.removeEventListener('beforeunload', listener);
}

import 'package:flutter/foundation.dart';
import 'package:score/features/app_update/app_update_native.dart'
    if (dart.library.js_interop) 'package:score/features/app_update/app_update_web.dart';

/// Whether a new version of the app has been installed while this one was
/// open.
///
/// Only the web has one: it is the service worker taking over the page (see
/// web/flutter_bootstrap.js). Everywhere else an app is updated by whatever
/// installed it, and is a new app the next time it starts.
ValueListenable<bool> get newVersionReady => platformNewVersionReady;

/// Starts again on the new version.
void startOnTheNewVersion() => platformStartOnTheNewVersion();

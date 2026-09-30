import 'package:flutter/foundation.dart';
import 'package:score/widgets/leave_page_warning_native.dart'
    if (dart.library.js_interop) 'package:score/widgets/leave_page_warning_web.dart';

/// Has the browser ask before the page is closed or reloaded, until the
/// callback it hands back is called. Only the web has a page to close; on a
/// device this does nothing.
VoidCallback warnBeforeLeavingThePage() => platformWarnBeforeLeavingThePage();

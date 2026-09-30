import 'package:flutter/material.dart';
import 'package:score/features/settings/theme_hint_native.dart'
    if (dart.library.js_interop) 'package:score/features/settings/theme_hint_web.dart';

/// Light or dark, as this device was last told, from where it can be read
/// before anything else is.
///
/// The choice itself is kept in the store with the other settings, and the
/// store takes a moment to open — a moment in which the web app would be drawn
/// in whatever the system is, which for a player who chose dark on a laptop set
/// to light is a white screen on a dark stage. So on the web it is also kept
/// in `localStorage`, which the page can read before the app has loaded at all
/// (see web/index.html), under the name the app before this one kept it by.
/// Elsewhere there is no page to paint first, and this is the system's.
ThemeMode rememberedThemeMode() => platformRememberedThemeMode();

/// Remembers [mode] where [rememberedThemeMode] reads it.
void rememberThemeMode(ThemeMode mode) => platformRememberThemeMode(mode);

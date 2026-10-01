import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// The name the app before this one kept it by, and web/index.html reads.
const _key = 'score-theme-mode';

ThemeMode platformRememberedThemeMode() {
  try {
    return switch (web.window.localStorage.getItem(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  } catch (_) {
    // A browser that keeps nothing for this site: it is only a hint.
    return ThemeMode.system;
  }
}

void platformRememberThemeMode(ThemeMode mode) {
  try {
    if (mode == ThemeMode.system) {
      web.window.localStorage.removeItem(_key);
    } else {
      web.window.localStorage.setItem(_key, mode.name);
    }
  } catch (_) {
    // As above.
  }
}

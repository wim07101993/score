import 'package:flutter/material.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';

/// How the page is lit: what it gives off, and how far from grey it is.
///
/// Both are shares between nothing and everything, and both belong to a reader
/// and a room rather than to an app.
typedef PageLook = ({double brightness, double warmth});

// What this device has been told to prefer, as it is stored.
//
// It belongs to the device rather than to the account: a player may read off a
// bright laptop at home and a dimmed tablet on a stand, signed in as the same
// person, and neither should decide the other. So it is kept on the device and
// never sent to the server.

const themeModeKey = 'theme_mode';

String pageLookKey(Brightness brightness) => 'page_look_${brightness.name}';

/// Following the system is what an app does when it has been told nothing,
/// so it is stored as nothing. A device that has never been asked and one
/// that has been put back to "follow the system" are the same device.
String? themeModeToStore(ThemeMode mode) =>
    mode == ThemeMode.system ? null : mode.name;

/// A stored mode, forgivingly.
///
/// Anything unreadable — a key from a version that named them differently, a
/// half-written value — is the system's choice rather than an app that will
/// not start.
ThemeMode readThemeMode(String? stored) {
  for (final mode in ThemeMode.values) {
    if (mode.name == stored) {
      return mode;
    }
  }
  return ThemeMode.system;
}

/// The page nobody has touched is stored as nothing, like the system's theme.
String? pageLookToStore(Brightness brightness, PageLook look) =>
    look == defaultPageLook(brightness)
    ? null
    : '${look.brightness},${look.warmth}';

/// A stored page, just as forgivingly: half of a pair of numbers, or none, is
/// the page nobody has touched rather than a page that cannot be drawn.
PageLook readPageLook(Brightness brightness, String? stored) {
  final fallback = defaultPageLook(brightness);
  final parts = stored?.split(',') ?? const [];
  if (parts.length != 2) {
    return fallback;
  }
  final lit = double.tryParse(parts.first);
  final warmth = double.tryParse(parts.last);
  if (lit == null || warmth == null) {
    return fallback;
  }
  return readable((brightness: lit, warmth: warmth));
}

/// [look], within what a page can be read off at.
PageLook readable(PageLook look) => (
  brightness: look.brightness.clamp(SheetPalette.dimmest, SheetPalette.full),
  warmth: look.warmth.clamp(0.0, 1.0),
);

/// Where the lamp starts. A white page in a lit room, and a dimmed, slightly
/// warm one in a dark one.
PageLook defaultPageLook(Brightness brightness) => brightness == Brightness.dark
    ? (brightness: SheetPalette.night, warmth: SheetPalette.nightWarmth)
    : (brightness: SheetPalette.full, warmth: 0.0);

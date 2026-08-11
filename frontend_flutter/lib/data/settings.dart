import 'package:flutter/material.dart';

import '../notation/score_sheet.dart';
import 'local_store.dart';

/// How the page is lit: what it gives off, and how far from grey it is.
///
/// Both are shares between nothing and everything, and both belong to a reader
/// and a room rather than to an app.
typedef PageLook = ({double brightness, double warmth});

/// What this device has been told to prefer.
///
/// It belongs to the device rather than to the account: a player may read off a
/// bright laptop at home and a dimmed tablet on a stand, signed in as the same
/// person, and neither should decide the other. So it is kept here and never
/// sent to the server.
class Settings extends ChangeNotifier {
  Settings._(this._store, this._themeMode, this._looks);

  /// Read before anything is drawn.
  ///
  /// The alternative is starting light and correcting a moment later, which on
  /// a dark stage is a white screen in somebody's face.
  static Future<Settings> load(LocalStore store) async {
    return Settings._(
      store,
      _readThemeMode(await store.readSetting(_themeKey)),
      {
        for (final brightness in Brightness.values)
          brightness: _readLook(
            await store.readSetting(_lookKey(brightness)),
            _defaultLookFor(brightness),
          ),
      },
    );
  }

  static const _themeKey = 'theme_mode';

  static String _lookKey(Brightness brightness) => 'page_look_${brightness.name}';

  final LocalStore _store;
  ThemeMode _themeMode;
  final Map<Brightness, PageLook> _looks;

  /// Light, dark, or whatever the machine says.
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    // On screen first: the write is a round trip to a database, and a player
    // who has just tapped "dark" in a dark room should not wait for it.
    notifyListeners();
    // Following the system is what an app does when it has been told nothing,
    // so it is stored as nothing. A device that has never been asked and one
    // that has been put back to "follow the system" are the same device.
    await _store.writeSetting(
        _themeKey, mode == ThemeMode.system ? null : mode.name);
  }

  /// How the page is lit when the app is [brightness].
  ///
  /// Kept apart for the two, because they are two different rooms: the lamp a
  /// reader wants at a lit desk is not the one they want at a gig, and being
  /// asked to set it again every time the sun goes down would be worse than not
  /// being asked at all.
  PageLook pageLook(Brightness brightness) =>
      _looks[brightness] ?? _defaultLookFor(brightness);

  Future<void> setPageLook(Brightness brightness, PageLook look) async {
    final held = (
      brightness: look.brightness.clamp(SheetPalette.dimmest, SheetPalette.full),
      warmth: look.warmth.clamp(0.0, 1.0),
    );
    if (held == pageLook(brightness)) {
      return;
    }
    _looks[brightness] = held;
    // A slider is dragged, not tapped: the page has to keep up with the thumb,
    // and the writing can happen behind it.
    notifyListeners();
    await _store.writeSetting(
      _lookKey(brightness),
      held == _defaultLookFor(brightness)
          ? null
          : '${held.brightness},${held.warmth}',
    );
  }

  /// Puts the page back to what it was before anybody touched it.
  Future<void> resetPageLook(Brightness brightness) =>
      setPageLook(brightness, _defaultLookFor(brightness));

  bool isPageLookDefault(Brightness brightness) =>
      pageLook(brightness) == _defaultLookFor(brightness);

  /// Where the lamp starts. A white page in a lit room, and a dimmed, slightly
  /// warm one in a dark one.
  static PageLook _defaultLookFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? (brightness: SheetPalette.night, warmth: SheetPalette.nightWarmth)
          : (brightness: SheetPalette.full, warmth: 0.0);

  /// A stored mode, forgivingly.
  ///
  /// Anything unreadable — a key from a version that named them differently, a
  /// half-written value — is the system's choice rather than an app that will
  /// not start.
  static ThemeMode _readThemeMode(String? stored) {
    for (final mode in ThemeMode.values) {
      if (mode.name == stored) {
        return mode;
      }
    }
    return ThemeMode.system;
  }

  /// A stored page, just as forgivingly: half of a pair of numbers, or none, is
  /// the page nobody has touched rather than a page that cannot be drawn.
  static PageLook _readLook(String? stored, PageLook fallback) {
    final parts = stored?.split(',') ?? const [];
    if (parts.length != 2) {
      return fallback;
    }
    final brightness = double.tryParse(parts.first);
    final warmth = double.tryParse(parts.last);
    if (brightness == null || warmth == null) {
      return fallback;
    }
    return (
      brightness: brightness.clamp(SheetPalette.dimmest, SheetPalette.full),
      warmth: warmth.clamp(0.0, 1.0),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/data/local_store.dart';
import 'package:score/data/settings.dart';
import 'package:score/notation/score_sheet.dart';

/// What the device remembers being told.
///
/// A player sets this once, in a room, and expects to find it that way at the
/// next rehearsal. That is the whole of what it has to do — but it is read
/// before the first frame, so what happens when the stored value is nonsense
/// matters more than it looks: the answer has to be a running app.

void main() {
  late LocalStore store;

  setUp(() async => store = await LocalStore.inMemory());

  test('a device that has never been asked follows the system', () async {
    final settings = await Settings.load(store);

    expect(settings.themeMode, ThemeMode.system);
  });

  test('what was chosen is what is found at the next start', () async {
    await (await Settings.load(store)).setThemeMode(ThemeMode.dark);

    // A different Settings on the same store: the app, started again.
    expect((await Settings.load(store)).themeMode, ThemeMode.dark);
  });

  test('going back to the system stores nothing rather than the word for it',
      () async {
    final settings = await Settings.load(store);
    await settings.setThemeMode(ThemeMode.light);
    await settings.setThemeMode(ThemeMode.system);

    expect(await store.readSetting('theme_mode'), isNull);
    expect((await Settings.load(store)).themeMode, ThemeMode.system);
  });

  test('the app is told, so the theme can change under it', () async {
    final settings = await Settings.load(store);
    var told = 0;
    settings.addListener(() => told++);

    await settings.setThemeMode(ThemeMode.dark);
    expect(told, 1);

    // Choosing what is already chosen is not a change to redraw for.
    await settings.setThemeMode(ThemeMode.dark);
    expect(told, 1);
  });

  test('a stored value nobody can read is the system, not a broken app',
      () async {
    await store.writeSetting('theme_mode', 'midnight');

    expect((await Settings.load(store)).themeMode, ThemeMode.system);
  });

  group('the lamp on the page', () {
    test('starts full up in the light and turned down in the dark', () async {
      final settings = await Settings.load(store);

      expect(settings.pageLook(Brightness.light).brightness, SheetPalette.full);
      expect(settings.pageLook(Brightness.dark).brightness, SheetPalette.night);
      expect(settings.pageLook(Brightness.light).warmth, 0);
    });

    test('is set for one page without touching the other', () async {
      final settings = await Settings.load(store);

      await settings.setPageLook(
          Brightness.dark, (brightness: 0.4, warmth: 0.5));

      expect(settings.pageLook(Brightness.dark).brightness, 0.4);
      expect(settings.pageLook(Brightness.light).brightness, SheetPalette.full,
          reason: 'a lit desk and a dark stage are two different rooms');
    });

    test('is where it was left at the next start', () async {
      await (await Settings.load(store))
          .setPageLook(Brightness.dark, (brightness: 0.22, warmth: 0.8));

      final reopened = await Settings.load(store);
      expect(reopened.pageLook(Brightness.dark).brightness, closeTo(0.22, 1e-9));
      expect(reopened.pageLook(Brightness.dark).warmth, closeTo(0.8, 1e-9));
    });

    test('cannot be turned below what can be read off', () async {
      final settings = await Settings.load(store);

      await settings.setPageLook(
          Brightness.dark, (brightness: 0.0, warmth: 3));

      expect(settings.pageLook(Brightness.dark).brightness,
          SheetPalette.dimmest);
      expect(settings.pageLook(Brightness.dark).warmth, 1);
    });

    test('put back is stored as nothing, the way it started', () async {
      final settings = await Settings.load(store);
      await settings.setPageLook(
          Brightness.dark, (brightness: 0.5, warmth: 0.5));
      expect(settings.isPageLookDefault(Brightness.dark), isFalse);

      await settings.resetPageLook(Brightness.dark);

      expect(settings.isPageLookDefault(Brightness.dark), isTrue);
      expect(await store.readSetting('page_look_dark'), isNull);
    });

    test('a stored page nobody can read is the page nobody has touched',
        () async {
      await store.writeSetting('page_look_dark', 'dim-ish');

      final settings = await Settings.load(store);
      expect(settings.pageLook(Brightness.dark).brightness, SheetPalette.night);
    });

    test('the page is told, so the sheet can keep up with the thumb', () async {
      final settings = await Settings.load(store);
      var told = 0;
      settings.addListener(() => told++);

      await settings.setPageLook(
          Brightness.dark, (brightness: 0.4, warmth: 0.3));
      expect(told, 1);

      // Landing on the value it already had is not a change to redraw for.
      await settings.setPageLook(
          Brightness.dark, (brightness: 0.4, warmth: 0.3));
      expect(told, 1);
    });
  });
}
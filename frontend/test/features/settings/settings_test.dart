import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/settings/behaviours/set_page_look.dart';
import 'package:score/features/settings/behaviours/set_theme_mode.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';

import '../../test_stores.dart';

/// What the device remembers being told.
///
/// A player sets this once, in a room, and expects to find it that way at the
/// next rehearsal. That is the whole of what it has to do — but it is read
/// before the first frame, so what happens when the stored value is nonsense
/// matters more than it looks: the answer has to be a running app.

void main() {
  late Stores store;
  late SetThemeMode setThemeMode;
  late SetPageLook setPageLook;

  setUp(() async {
    store = await Stores.inMemory();
    setThemeMode = SetThemeMode(store: store.settings);
    setPageLook = SetPageLook(store: store.settings);
  });

  /// What the app reads when it starts: a notifier over the store, once it
  /// holds what the store holds.
  Future<SettingsNotifier> start() async {
    final settings = SettingsNotifier(store: store.settings);
    addTearDown(settings.dispose);
    await settings.ready;
    return settings;
  }

  /// Lets what was just written reach whoever follows the store.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a device that has never been asked follows the system', () async {
    expect((await start()).themeMode, ThemeMode.system);
  });

  test('what was chosen is what is found at the next start', () async {
    await setThemeMode.action(ThemeMode.dark, null);

    expect((await start()).themeMode, ThemeMode.dark);
  });

  test('going back to the system stores nothing rather than the word for it',
      () async {
    await setThemeMode.action(ThemeMode.light, null);
    await setThemeMode.action(ThemeMode.system, null);

    expect(await store.settings.read('theme_mode'), isNull);
    expect((await start()).themeMode, ThemeMode.system);
  });

  test('the app is told, so the theme can change under it', () async {
    final settings = await start();
    var told = 0;
    settings.addListener(() => told++);

    await setThemeMode.action(ThemeMode.dark, null);
    await settle();
    expect(told, 1);
    expect(settings.themeMode, ThemeMode.dark);
  });

  test('a stored value nobody can read is the system, not a broken app',
      () async {
    await store.settings.write('theme_mode', 'midnight');

    expect((await start()).themeMode, ThemeMode.system);
  });

  test('a behaviour that fails says so rather than throwing', () async {
    final failing = SetThemeMode(store: store.settings);
    await store.databases.data.close();

    expect(await failing(ThemeMode.dark), isA<Failed<void>>());
  });

  group('the lamp on the page', () {
    test('starts full up in the light and turned down in the dark', () async {
      final settings = await start();

      expect(settings.pageLook(Brightness.light).brightness, SheetPalette.full);
      expect(settings.pageLook(Brightness.dark).brightness, SheetPalette.night);
      expect(settings.pageLook(Brightness.light).warmth, 0);
    });

    test('is set for one page without touching the other', () async {
      await setPageLook.action(
        const SetPageLookParams(
          brightness: Brightness.dark,
          look: (brightness: 0.4, warmth: 0.5),
        ),
        null,
      );

      final settings = await start();
      expect(settings.pageLook(Brightness.dark).brightness, 0.4);
      expect(settings.pageLook(Brightness.light).brightness, SheetPalette.full,
          reason: 'a lit desk and a dark stage are two different rooms');
    });

    test('is where it was left at the next start', () async {
      await setPageLook.action(
        const SetPageLookParams(
          brightness: Brightness.dark,
          look: (brightness: 0.22, warmth: 0.8),
        ),
        null,
      );

      final reopened = await start();
      expect(reopened.pageLook(Brightness.dark).brightness, closeTo(0.22, 1e-9));
      expect(reopened.pageLook(Brightness.dark).warmth, closeTo(0.8, 1e-9));
    });

    test('cannot be turned below what can be read off', () async {
      await setPageLook.action(
        const SetPageLookParams(
          brightness: Brightness.dark,
          look: (brightness: 0.0, warmth: 3),
        ),
        null,
      );

      final settings = await start();
      expect(settings.pageLook(Brightness.dark).brightness,
          SheetPalette.dimmest);
      expect(settings.pageLook(Brightness.dark).warmth, 1);
    });

    test('put back is stored as nothing, the way it started', () async {
      final settings = await start();
      await setPageLook.action(
        const SetPageLookParams(
          brightness: Brightness.dark,
          look: (brightness: 0.5, warmth: 0.5),
        ),
        null,
      );
      await settle();
      expect(settings.isPageLookDefault(Brightness.dark), isFalse);

      await setPageLook.action(
        const SetPageLookParams(brightness: Brightness.dark),
        null,
      );
      await settle();

      expect(settings.isPageLookDefault(Brightness.dark), isTrue);
      expect(await store.settings.read('page_look_dark'), isNull);
    });

    test('a stored page nobody can read is the page nobody has touched',
        () async {
      await store.settings.write('page_look_dark', 'dim-ish');

      final settings = await start();
      expect(settings.pageLook(Brightness.dark).brightness, SheetPalette.night);
    });

    test('the page is told, so the sheet follows what is kept', () async {
      final settings = await start();
      var told = 0;
      settings.addListener(() => told++);

      await setPageLook.action(
        const SetPageLookParams(
          brightness: Brightness.dark,
          look: (brightness: 0.4, warmth: 0.3),
        ),
        null,
      );
      await settle();
      expect(told, 1);
      expect(settings.pageLook(Brightness.dark).brightness, 0.4);
    });
  });
}

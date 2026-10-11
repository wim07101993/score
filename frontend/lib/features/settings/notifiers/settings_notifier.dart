import 'package:flutter/material.dart';
import 'package:score/features/settings/models.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/notifiers/store_notifier.dart';

typedef DeviceSettings = ({
  ThemeMode themeMode,
  Map<Brightness, PageLook> looks,
});

/// What this device has been told to prefer, as the store has it.
class SettingsNotifier({
  required final SettingsStore store,
}) extends StreamNotifier<DeviceSettings> {
  this
    : super(
        initial: (
          themeMode: ThemeMode.system,
          looks: {
            for (final brightness in Brightness.values)
              brightness: defaultPageLook(brightness),
          },
        ),
      ) {
    follow(
      store
          .watch(themeModeKey)
          .map(
            (stored) => (
              themeMode: readThemeMode(stored),
              looks: value.looks,
            ),
          ),
    );
    for (final brightness in Brightness.values) {
      follow(
        store
            .watch(pageLookKey(brightness))
            .map(
              (stored) => (
                themeMode: value.themeMode,
                looks: {
                  ...value.looks,
                  brightness: readPageLook(brightness, stored),
                },
              ),
            ),
      );
    }
  }

  /// Light, dark, or whatever the machine says.
  ThemeMode get themeMode => value.themeMode;

  /// How the page is lit when the app is [brightness].
  ///
  /// Kept apart for the two, because they are two different rooms: the lamp a
  /// reader wants at a lit desk is not the one they want at a gig, and being
  /// asked to set it again every time the sun goes down would be worse than not
  /// being asked at all.
  PageLook pageLook(Brightness brightness) =>
      value.looks[brightness] ?? defaultPageLook(brightness);

  bool isPageLookDefault(Brightness brightness) =>
      pageLook(brightness) == defaultPageLook(brightness);
}

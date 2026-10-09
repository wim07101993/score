import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:score/features/settings/models.dart';
import 'package:score/features/settings/storage/settings_store.dart';

class const SetPageLookParams({
  /// Which page: the one the app shows when it is light, or when it is dark.
  required final Brightness brightness,

  /// How it is lit from now on. Null puts it back to what it was before
  /// anybody touched it.
  final PageLook? look,
});

/// Lights the page, and keeps it lit that way for the next start.
///
/// Called when a drag lets go rather than for every step of it: a thumb reports
/// every pixel it crosses, and writing each of those is a round trip per frame
/// for values nobody will ever read back. The drag itself is shown by the page
/// it happens on.
class SetPageLook({
  super.monitor,
  required final SettingsStore store,
}) extends Behaviour<SetPageLookParams, void> {
  @override
  String get description => 'lighting the page';

  @override
  Future<void> action(SetPageLookParams input, BehaviourTrack? track) async {
    final brightness = input.brightness;
    final look = readable(
      input.look ?? defaultPageLook(brightness),
    );
    await store.write(
      pageLookKey(brightness),
      pageLookToStore(brightness, look),
    );
  }
}

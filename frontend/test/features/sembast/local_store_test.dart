import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/legacy_store.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/settings/settings.dart';

/// Bringing over what the app before this one kept.
///
/// It runs once, on a device nobody is watching, and whatever it gets wrong is
/// found a week later on a stage: a white page in a dark room, or a score that
/// never picks up the corrected upload. So what it keeps, what it leaves and
/// what it rewrites on the way are pinned down here.

void main() {
  late LocalStore store;

  setUp(() async => store = await LocalStore.inMemory());

  Future<LegacyData?> Function() reading(LegacyData? legacy) =>
      () async => legacy;

  const deviceClock = '2031-01-01T00:00:00.000Z';

  group('preferences', () {
    test('are brought over without any records alongside them', () async {
      await store.bringOverLegacyData(
        read: reading(const LegacyData(
          themeMode: 'dark',
          pageLookLight: '0.9,0.1',
          pageLookDark: '0.4,0.6',
        )),
      );

      final settings = await Settings.load(store);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.pageLook(Brightness.light),
          (brightness: 0.9, warmth: 0.1));
      expect(settings.pageLook(Brightness.dark),
          (brightness: 0.4, warmth: 0.6));
    });

    test('do not overwrite what this app has been told since', () async {
      await store.writeSetting('theme_mode', 'light');

      await store.bringOverLegacyData(
        read: reading(const LegacyData(themeMode: 'dark')),
      );

      expect(await store.readSetting('theme_mode'), 'light');
    });

    test('are brought over on a device that already brought over the rest',
        () async {
      await store.writeSetting('legacy_data_brought_over', 'then');
      await store.writeSetting('legacy_collections_brought_over', 'then');

      await store.bringOverLegacyData(
        read: reading(const LegacyData(
          themeMode: 'dark',
          scores: [
            {'id': 'let-go-of', 'title': 'Gone since'},
          ],
        )),
      );

      expect(await store.readSetting('theme_mode'), 'dark');
      // What was brought over before is not read again on their account.
      expect(await store.readScores(), isEmpty);
    });

    test('are brought over once', () async {
      await store.bringOverLegacyData(
        read: reading(const LegacyData(themeMode: 'dark')),
      );
      await store.writeSetting('theme_mode', null);

      await store.bringOverLegacyData(
        read: reading(const LegacyData(themeMode: 'dark')),
      );

      expect(await store.readSetting('theme_mode'), isNull);
    });

    test('a theme mode the old app never meant to write is left behind',
        () async {
      await store.bringOverLegacyData(
        read: reading(const LegacyData(themeMode: 'system')),
      );

      expect(await store.readSetting('theme_mode'), isNull);
    });

    test('the user comes over when this app can read them back', () async {
      final json = jsonEncode({
        'name': 'Ann',
        'subject': '42',
        'email': 'ann@example.com',
        'roles': {'score_viewer': {}},
        'claims': {'sub': '42'},
        'rolesKey': 'roles',
      });

      await store.bringOverLegacyData(
        read: reading(LegacyData(userInfo: json)),
      );

      final kept = await store.readSetting('app_user_info');
      final user = UserInfo.fromJson(jsonDecode(kept!) as Map<String, dynamic>);
      expect(user.subject, '42');
      expect(user.isScoreViewer, isTrue);
    });

    test('a user this app could not read back is left behind', () async {
      await store.bringOverLegacyData(
        read: reading(LegacyData(
          userInfo: jsonEncode({
            'subject': '42',
            'roles': ['score_viewer'],
          }),
        )),
      );
      expect(await store.readSetting('app_user_info'), isNull);

      final other = await LocalStore.inMemory();
      await other.bringOverLegacyData(
        read: reading(const LegacyData(userInfo: 'not json')),
      );
      expect(await other.readSetting('app_user_info'), isNull);
    });
  });

  group('records', () {
    test('a score forgets the moments read off the device clock', () async {
      await store.bringOverLegacyData(
        read: reading(const LegacyData(
          scores: [
            {
              'id': 's1',
              'title': 'Tonight',
              'last_synced_at': deviceClock,
              'last_fetched_file_at': deviceClock,
            },
          ],
          musicXml: {'s1': '<score-partwise/>'},
        )),
      );

      final [score] = await store.readScores();
      expect(score['title'], 'Tonight');
      expect(score.containsKey('last_synced_at'), isFalse);
      expect(score.containsKey('last_fetched_file_at'), isFalse);
      expect(await store.readMusicXml('s1'), '<score-partwise/>');
    });

    test('a set or a collection the server had still says so, from the start '
        'of time', () async {
      await store.bringOverLegacyData(
        read: reading(const LegacyData(
          sets: [
            {'id': 'synced', 'last_synced_at': deviceClock},
            {'id': 'never', 'last_synced_at': null},
          ],
          collections: [
            {'id': 'synced', 'last_synced_at': deviceClock},
            {'id': 'never'},
          ],
        )),
      );

      final sets = {
        for (final set in await store.readSets()) set['id']: set,
      };
      expect(sets['synced']!['last_synced_at'], '1970-01-01T00:00:00.000Z');
      expect(sets['never']!['last_synced_at'], isNull);

      final collections = {
        for (final c in await store.readCollections()) c['id']: c,
      };
      expect(
          collections['synced']!['last_synced_at'], '1970-01-01T00:00:00.000Z');
      expect(collections['never']!.containsKey('last_synced_at'), isFalse);
    });

    test('a record this app wrote is left as it is', () async {
      await store.writeScores([
        {'id': 's1', 'title': 'Newer', 'last_synced_at': deviceClock},
      ]);

      await store.bringOverLegacyData(
        read: reading(const LegacyData(scores: [
          {'id': 's1', 'title': 'Older'},
        ])),
      );

      final [score] = await store.readScores();
      expect(score['title'], 'Newer');
      expect(score['last_synced_at'], deviceClock);
    });
  });

  test('a reading that fails is tried again at the next start', () async {
    await store.bringOverLegacyData(read: () async => throw StateError('no'));
    await store.bringOverLegacyData(
      read: reading(const LegacyData(themeMode: 'dark')),
    );

    expect(await store.readSetting('theme_mode'), 'dark');
  });
}

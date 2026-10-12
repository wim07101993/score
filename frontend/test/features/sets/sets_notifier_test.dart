import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';

import '../../test_stores.dart';

ScoreSet _set(String id, DateTime lastChangedAt) => ScoreSet(
  id: id,
  title: id,
  description: '',
  entries: const [],
  sharedWith: const [],
  isOwner: true,
  lastChangedAt: lastChangedAt,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('follows the store, newest first, without the deleted ones', () async {
    final store = await Stores.inMemory();
    final sets = SetsNotifier(store: store.sets);
    addTearDown(sets.dispose);

    await store.sets.putAll([
      _set('old', DateTime.utc(2026)),
      _set('new', DateTime.utc(2026, 6)),
      _set('gone', DateTime.utc(2026, 7)),
    ]);
    await store.sets.removeWithIds(['gone']);
    await _settle();

    expect(sets.sets.map((set) => set.id), ['new', 'old']);
    expect(sets.getSet('gone'), isNull);
    expect(sets.getSet('old')?.title, 'old');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:score/notifiers/set_notifier.dart';

void main() {
  late SetNotifier<String> notifier;
  late int notified;

  setUp(() {
    notifier = SetNotifier({'a', 'b'});
    notified = 0;
    notifier.addListener(() => notified++);
  });

  tearDown(() => notifier.dispose());

  test('tells its listeners when an element is added', () {
    expect(notifier.add('c'), isTrue);
    expect(notifier.value, {'a', 'b', 'c'});
    expect(notified, 1);
  });

  test('stays quiet when what is added is already there', () {
    expect(notifier.add('a'), isFalse);
    notifier.addAll(['a', 'b']);
    expect(notified, 0);
  });

  test('tells its listeners when an element is removed', () {
    expect(notifier.remove('a'), isTrue);
    expect(notifier.value, {'b'});
    expect(notified, 1);
  });

  test('stays quiet when nothing is removed', () {
    expect(notifier.remove('z'), isFalse);
    notifier
      ..removeAll(['z'])
      ..removeWhere((element) => element == 'z')
      ..retainAll(['a', 'b'])
      ..retainWhere((_) => true);
    expect(notified, 0);
  });

  test('tells its listeners once when several elements change at once', () {
    notifier.addAll(['c', 'd']);
    notifier.retainWhere((element) => element != 'a');
    expect(notifier.value, {'b', 'c', 'd'});
    expect(notified, 2);
  });

  test('stays quiet when cleared while empty', () {
    notifier.clear();
    notifier.clear();
    expect(notifier.isEmpty, isTrue);
    expect(notified, 1);
  });

  test('hands out a value that cannot be changed behind its back', () {
    expect(() => notifier.value.add('c'), throwsUnsupportedError);
  });

  test('reads like the set it holds', () {
    expect(notifier.length, 2);
    expect(notifier.contains('a'), isTrue);
    expect(notifier.map((element) => element.toUpperCase()), ['A', 'B']);
    expect(notifier.fold<int>(0, (sum, element) => sum + element.length), 2);
    expect(notifier.union({'c'}), {'a', 'b', 'c'});
    expect(notifier.intersection({'b', 'c'}), {'b'});
    expect(notifier.join(','), 'a,b');
  });
}

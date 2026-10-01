import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/app.dart';

void main() {
  test('a sync that is asked for finishes', () async {
    final oneAtATime = OneAtATime();
    var ran = 0;

    await oneAtATime('sets', () async => ran++)
        .timeout(const Duration(seconds: 1));

    expect(ran, 1);
  });

  test('one asked for while one is running goes once after it', () async {
    final oneAtATime = OneAtATime();
    final first = Completer<void>();
    var ran = 0;
    Future<void> sync() async {
      ran++;
      if (ran == 1) await first.future;
    }

    final running = oneAtATime('sets', sync);
    final asked = [oneAtATime('sets', sync), oneAtATime('sets', sync)];
    first.complete();

    await Future.wait([running, ...asked])
        .timeout(const Duration(seconds: 1));
    expect(ran, 2);

    // And the kind is free again afterwards.
    await oneAtATime('sets', sync).timeout(const Duration(seconds: 1));
    expect(ran, 3);
  });
}

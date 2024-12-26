import 'dart:async';

import 'package:flutter/foundation.dart';

class StreamListenable<T> extends ChangeNotifier implements ValueListenable<T> {
  StreamListenable({
    required Stream<T> stream,
    required T initialValue,
  }) : _value = initialValue {
    _subscription = stream.listen((value) {
      _value = value;
      notifyListeners();
    });
  }

  static StreamListenable<T?> nullable<T>({
    required Stream<T> stream,
  }) {
    return StreamListenable(stream: stream, initialValue: null);
  }

  late final StreamSubscription<T> _subscription;

  T _value;

  @override
  T get value => _value;

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    super.dispose();
  }
}

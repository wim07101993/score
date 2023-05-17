import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class ReadOnlyGlobalValue<T> {
  T get value;
  Stream<T> get changes;

  Future<ReadOnlyGlobalValue<T>> initialize();
}

abstract class GlobalValue<T> implements ReadOnlyGlobalValue<T> {
  set value(T newValue);
  @override
  T get value;
}

class GlobalValueListenable<T> extends ChangeNotifier
    implements ValueListenable<T> {
  GlobalValueListenable({
    required this.globalValue,
  }) {
    _subscription = globalValue.changes.listen((event) => notifyListeners());
  }

  final ReadOnlyGlobalValue<T> globalValue;

  late final StreamSubscription _subscription;

  @override
  T get value => globalValue.value;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

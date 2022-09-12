import 'package:flutter/foundation.dart';

class MultiValueListenable<T> extends ChangeNotifier
    implements ValueListenable<List<T>> {
  MultiValueListenable(
    List<ValueListenable<T>> valueListenables,
  ) : valueListenables = valueListenables.toList() {
    for (final valueListenable in valueListenables) {
      valueListenable.addListener(notifyListeners);
    }
  }

  final List<ValueListenable<T>> valueListenables;

  @override
  List<T> get value => valueListenables.map<T>((v) => v.value).toList();

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  void addValueListenable(ValueListenable<T> valueListenable) {
    valueListenables.add(valueListenable);
    valueListenable.addListener(notifyListeners);
  }

  void removeValueListenableAt(int index) {
    valueListenables[index].removeListener(notifyListeners);
    valueListenables.removeAt(index);
  }

  void removeValueListenable(ValueListenable<T> valueListenable) {
    valueListenable.removeListener(notifyListeners);
    valueListenables.remove(valueListenable);
  }

  void clear() {
    while (valueListenables.isNotEmpty) {
      removeValueListenable(valueListenables.first);
    }
  }
}

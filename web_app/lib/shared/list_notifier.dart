import 'package:flutter/material.dart';

class ListNotifier<T> extends ValueNotifier<List<T>> {
  ListNotifier(super.value);

  factory ListNotifier.empty() => ListNotifier(List.empty(growable: true));

  int get length => value.length;

  T operator [](int index) => value[index];

  void operator []=(int index, T newItem) {
    value[index] = newItem;
    notifyListeners();
  }

  void add(T item) {
    value.add(item);
    notifyListeners();
  }

  void removeAt(int index) {
    value.removeAt(index);
    notifyListeners();
  }
}

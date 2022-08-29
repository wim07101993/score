import 'package:flutter/material.dart';

class ListNotifier<T> extends ValueNotifier<List<T>> {
  ListNotifier(
    super.value, {
    required this.maxLength,
  });

  factory ListNotifier.empty({
    required int maxLength,
  }) {
    return ListNotifier(List.empty(growable: true), maxLength: maxLength);
  }

  final int maxLength;

  int get length => value.length;

  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
  bool get canAddItem => value.length < maxLength;

  T operator [](int index) => value[index];

  void operator []=(int index, T newItem) {
    value[index] = newItem;
    notifyListeners();
  }

  void add(T item) {
    if (!canAddItem) {
      throw Exception('Cannot add add item. Max number of items reached');
    }
    value.add(item);
    notifyListeners();
  }

  void removeAt(int index) {
    value.removeAt(index);
    notifyListeners();
  }
}

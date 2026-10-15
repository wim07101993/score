import 'package:flutter/foundation.dart';

class SetNotifier<T> extends ChangeNotifier
    implements ValueListenable<Set<T>>, Set<T> {
  SetNotifier(
    Set<T> value,
  ) : _value = value.toSet();

  final Set<T> _value;

  @override
  bool add(T value) {
    if (_value.add(value)) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void addAll(Iterable<T> elements) {
    final lengthBefore = _value.length;
    _value.addAll(elements);
    if (_value.length != lengthBefore) {
      notifyListeners();
    }
  }

  @override
  bool any(bool Function(T element) test) => _value.any(test);

  @override
  Set<R> cast<R>() => _value.cast();

  @override
  void clear() {
    if (_value.isEmpty) {
      return;
    }
    _value.clear();
    notifyListeners();
  }

  @override
  bool contains(Object? value) => _value.contains(value);

  @override
  bool containsAll(Iterable<Object?> other) => _value.containsAll(other);

  @override
  Set<T> difference(Set<Object?> other) => _value.difference(other);

  @override
  T elementAt(int index) => _value.elementAt(index);

  @override
  bool every(bool Function(T element) test) => _value.every(test);

  @override
  Iterable<TOut> expand<TOut>(Iterable<TOut> Function(T element) toElements) {
    return _value.expand(toElements);
  }

  @override
  T get first => _value.first;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.firstWhere(test, orElse: orElse);
  }

  @override
  TOut fold<TOut>(
    TOut initialValue,
    TOut Function(TOut previousValue, T element) combine,
  ) {
    return _value.fold(initialValue, combine);
  }

  @override
  Iterable<T> followedBy(Iterable<T> other) => _value.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _value.forEach(action);

  @override
  Set<T> intersection(Set<Object?> other) => _value.intersection(other);

  @override
  bool get isEmpty => _value.isEmpty;

  @override
  bool get isNotEmpty => _value.isNotEmpty;

  @override
  Iterator<T> get iterator => _value.iterator;

  @override
  String join([String separator = '']) => _value.join(separator);

  @override
  T get last => _value.last;

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.lastWhere(test, orElse: orElse);
  }

  @override
  int get length => _value.length;

  @override
  T? lookup(Object? object) => _value.lookup(object);

  @override
  Iterable<TOut> map<TOut>(TOut Function(T e) toElement) =>
      _value.map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) => _value.reduce(combine);

  @override
  bool remove(Object? value) {
    if (_value.remove(value)) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    final lengthBefore = _value.length;
    _value.removeAll(elements);
    if (_value.length != lengthBefore) {
      notifyListeners();
    }
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final lengthBefore = _value.length;
    _value.removeWhere(test);
    if (_value.length != lengthBefore) {
      notifyListeners();
    }
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final lengthBefore = _value.length;
    _value.retainAll(elements);
    if (_value.length != lengthBefore) {
      notifyListeners();
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    final lengthBefore = _value.length;
    _value.retainWhere(test);
    if (_value.length != lengthBefore) {
      notifyListeners();
    }
  }

  @override
  T get single => _value.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> skip(int count) => _value.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _value.skipWhile(test);

  @override
  Iterable<T> take(int count) => _value.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _value.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) => _value.toList(growable: growable);

  @override
  Set<T> toSet() => _value.toSet();

  @override
  Set<T> union(Set<T> other) => _value.union(other);

  @override
  Set<T> get value => Set.unmodifiable(_value);

  @override
  Iterable<T> where(bool Function(T element) test) => _value.where(test);

  @override
  Iterable<TOut> whereType<TOut>() => _value.whereType();
}

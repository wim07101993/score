import 'package:flutter/material.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/notifiers/set_notifier.dart';

class ScoreFilter extends ChangeNotifier {
  ScoreFilter()
    : query = TextEditingController(),
      composers = SetNotifier({}),
      lyricists = SetNotifier({}),
      instruments = SetNotifier({}),
      languages = SetNotifier({}),
      tags = SetNotifier({}) {
    _subscribeToAll();
  }

  final TextEditingController query;
  final SetNotifier<String> composers;
  final SetNotifier<String> lyricists;
  final SetNotifier<String> instruments;
  final SetNotifier<String> languages;
  final SetNotifier<String> tags;

  int get count =>
      composers.length +
      lyricists.length +
      instruments.length +
      languages.length +
      tags.length;

  bool call(Score score) {
    return _fieldContainsAny(score.creators.composers, composers) &&
        _fieldContainsAny(score.creators.lyricists, lyricists) &&
        _fieldContainsAny(
          score.instruments.map(instrumentName).toList(growable: false),
          instruments,
        ) &&
        _fieldContainsAny(score.languages, languages) &&
        _fieldContainsAny(score.tags, tags) &&
        score.matches(query.text);
  }

  bool _fieldContainsAny(
    List<String> field,
    Set<String> possibilities,
  ) {
    if (possibilities.isEmpty) {
      return true;
    }
    return field.any(possibilities.contains);
  }

  void clear() {
    holdChangesWhile(() {
      composers.clear();
      lyricists.clear();
      instruments.clear();
      languages.clear();
      tags.clear();
    });
  }

  void _subscribeToAll() {
    query.addListener(notifyListeners);
    composers.addListener(notifyListeners);
    lyricists.addListener(notifyListeners);
    instruments.addListener(notifyListeners);
    languages.addListener(notifyListeners);
    tags.addListener(notifyListeners);
  }

  void _unsubscribeToAll() {
    query.removeListener(notifyListeners);
    composers.removeListener(notifyListeners);
    lyricists.removeListener(notifyListeners);
    instruments.removeListener(notifyListeners);
    languages.removeListener(notifyListeners);
    tags.removeListener(notifyListeners);
  }

  void holdChangesWhile(void Function() func) {
    _unsubscribeToAll();
    try {
      func();
    } finally {
      _subscribeToAll();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _unsubscribeToAll();
    query.dispose();
    composers.dispose();
    lyricists.dispose();
    instruments.dispose();
    languages.dispose();
    tags.dispose();
    super.dispose();
  }
}

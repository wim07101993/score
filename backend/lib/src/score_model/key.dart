import 'package:score_backend/src/musicxml/models/aliases.g.dart';
import 'package:score_backend/src/musicxml/models/enums.g.dart';

sealed class Key {}

class TraditionalKey implements Key {
  const TraditionalKey({
    required this.fifths,
    required this.cancel,
    required this.mode,
  });

  final int fifths;
  final KeyCancel? cancel;
  final Mode? mode;
}

class KeyCancel {
  const KeyCancel({
    required this.fifths,
    required this.location,
  });

  final int fifths;
  final CancelLocation location;
}

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/auth_feature.dart';
import 'package:score/features/auth/models/user_value.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/firebase/firebase_feature.dart';
import 'package:score/shared/models/score.dart';

class UploadFeature extends Feature {
  const UploadFeature();

  @override
  List<Type> get dependencies => [AuthFeature, FirebaseFeature];

  @override
  Future<void> install(GetIt getIt) {
    final user = getIt<UserValue>();
    if (user.value != null) {
      upload();
    } else {
      getIt<UserValue>()
          .changes
          .firstWhere((user) => user != null)
          .then((u) => upload());
    }
    return Future.value();
  }

  Future<void> upload() async {
    final collection = FirebaseFirestore.instance.collection("scores");
    final json1 = await rootBundle.loadString('assets/scores1.json');
    final json2 = await rootBundle.loadString('assets/scores2.json');
    final scores = [
      ...jsonDecode(json1) as List<dynamic>,
      ...jsonDecode(json2) as List<dynamic>,
    ]
        .whereType<Map<String, dynamic>>()
        .map((e) => _Score.fromJson(e))
        .expand(originalToScore)
        .map(scoreToJson);

    for (final score in scores) {
      print(score);
      await collection.add(score);
    }

    print('------------------------------------DONE');
  }
}

class _Score {
  const _Score({
    required this.title,
    required this.composers,
    required this.arrangements,
  });

  factory _Score.fromJson(Map<String, dynamic> json) {
    return _Score(
      title: json['Title'] as String,
      composers: (json['Composers'] as List)
          .whereType<String>()
          .toList(growable: false),
      arrangements: (json['Arrangements'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => _Arrangement.fromJson(e))
          .toList(growable: false),
    );
  }

  final String title;
  final List<String> composers;
  final List<_Arrangement> arrangements;
}

class _Arrangement {
  const _Arrangement({
    required this.name,
    required this.lyricists,
    required this.parts,
  });

  factory _Arrangement.fromJson(Map<String, dynamic> json) {
    return _Arrangement(
      name: json['Name'] as String,
      lyricists: (json['Lyricists'] as List)
          .whereType<String>()
          .toList(growable: false),
      parts: (json['Parts'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => _Part.fromJson(e))
          .toList(growable: false),
    );
  }

  final String name;
  final List<String> lyricists;
  final List<_Part> parts;
}

class _Part {
  const _Part({
    required this.description,
    required this.instruments,
    required this.links,
  });

  factory _Part.fromJson(Map<String, dynamic> json) {
    return _Part(
      description: json['Description'] as String,
      instruments: (json['Instruments'] as List)
          .whereType<String>()
          .toList(growable: false),
      links:
          (json['Links'] as List).whereType<String>().toList(growable: false),
    );
  }

  final String description;
  final List<String> instruments;
  final List<String> links;
}

Iterable<Score> originalToScore(_Score original) sync* {
  for (final arrangement in original.arrangements) {
    yield Score(
      title: original.title,
      arrangementName: arrangement.name,
      alsoKnownAs: const [],
      composers: original.composers,
      lyricists: arrangement.lyricists,
      parts: arrangement.parts.map((part) {
        return Part(
          name: part.description,
          instruments: part.instruments,
          files: part.links
              .map((link) => LinkedFile(link: link))
              .toList(growable: true),
        );
      }).toList(growable: false),
    );
  }
}

Map<String, dynamic> scoreToJson(Score score) {
  return {
    'title': score.title,
    'arrangementName': score.arrangementName,
    'alsoKnownAs': score.alsoKnownAs,
    'composers': score.composers,
    'lyricists': score.lyricists,
    'parts': score.parts.map(
      (part) {
        return {
          'name': part.name,
          'instruments': part.instruments,
          'files': part.files.map(
            (file) =>
                file is LinkedFile ? {'link': file.link} : <String, dynamic>{},
          ),
        };
      },
    ),
  };
}

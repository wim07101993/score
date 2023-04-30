import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final collection = FirebaseFirestore.instance.collection("scoresx");
  final json = await rootBundle.loadString('assets/scoresx.json');
  final scores = jsonDecode(json) as List<dynamic>;
  for (final score in scores.whereType<Map<String, dynamic>>()) {
    print('adding score ${score["title"]}');
    await collection.add(score);
  }
}

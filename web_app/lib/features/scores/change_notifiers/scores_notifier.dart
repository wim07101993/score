import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/data/firebase/firestore_extensions.dart';

class ScoresNotifier extends ChangeNotifier {
  ScoresNotifier({
    required this.firestore,
    required this.logger,
  }) {
    _collectionSubscription =
        firestore.scoreCollection.snapshots().listen(onCollectionChanged);
    getInitialCollection();
  }

  final FirebaseFirestore firestore;
  final Logger logger;

  late final StreamSubscription _collectionSubscription;

  var _cache = List<Map<String, dynamic>>.empty(growable: true);

  void onCollectionChanged(QuerySnapshot<Map<String, dynamic>> event) {
    for (final docChange in event.docChanges) {}
  }

  @override
  void dispose() {
    super.dispose();
    _collectionSubscription.cancel();
  }

  Future<void> getInitialCollection() async {}
}

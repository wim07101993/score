import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:score/shared/dependency_management/global_value.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String? email;
  final String? name;
}

class UserValue implements ReadOnlyGlobalValue<User?> {
  UserValue({
    required this.firebaseAuth,
    required this.firebaseUserConverter,
  });

  final FirebaseAuth firebaseAuth;
  final FirebaseUserConverter firebaseUserConverter;
  final StreamController<User?> _streamController =
      StreamController.broadcast();

  User? _value;
  StreamSubscription? _firebaseSubscription;

  @override
  User? get value => _value;

  @override
  Stream<User?> get changes => _streamController.stream;

  @override
  Future<UserValue> initialize() async {
    void onUserChanged(firebase.User? user) {
      _value = firebaseUserConverter.convert(user);
      _streamController.add(_value);
    }

    _firebaseSubscription = firebaseAuth.userChanges().listen(onUserChanged);
    onUserChanged(firebaseAuth.currentUser);
    return Future.value(this);
  }

  Future<void> dispose() {
    return Future.wait(
      [
        _firebaseSubscription?.cancel(),
      ].whereType<Future>(),
    );
  }
}

class FirebaseUserConverter {
  const FirebaseUserConverter();

  User? convert(firebase.User? input) {
    if (input == null) {
      return null;
    }
    return User(
      id: input.uid,
      email: input.email,
      name: input.displayName,
    );
  }
}

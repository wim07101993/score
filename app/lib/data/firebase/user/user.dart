import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:score/data/firebase/auth/auth_changes.dart';

import 'access_levels.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String displayName,
    required AccessLevels accessLevels,
  }) = _User;

  factory User.empty({
    required String displayName,
  }) {
    return User(
      displayName: displayName,
      accessLevels: const AccessLevels(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

class UserRepository {
  UserRepository({
    required AuthChanges authChanges,
    required FirebaseFirestore firestore,
  })  : _authChanges = authChanges,
        _users = firestore.collection('users').withConverter(
              fromFirestore: fromFirestore,
              toFirestore: toFirestore,
            );

  final AuthChanges _authChanges;
  final CollectionReference<User?> _users;
  StreamController<User?>? _controller;
  String? _uid;
  StreamSubscription? _userChangeSubscription;

  Future<User?> user() async {
    final authUser = _authChanges.value;
    if (authUser == null) {
      return null;
    }
    final docRef = _users.doc(authUser.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final user = User.empty(displayName: authUser.displayName ?? 'anonymous');
      await docRef.set(user);
      return user;
    }
    return doc.data();
  }

  Stream<User?> get changes {
    var controller = _controller;
    if (controller != null) {
      return controller.stream;
    }
    _controller = controller = StreamController<User?>.broadcast();
    _authChanges.addListener(_onAuthUserChanged);
    return controller.stream;
  }

  Future<void> _onAuthUserChanged() async {
    final uid = _authChanges.value?.uid;
    if (_uid == uid) {
      return;
    }
    _uid = uid;
    if (uid == null) {
      _userChangeSubscription?.cancel();
      _userChangeSubscription = null;
      _controller?.add(null);
    } else {
      final doc = _users.doc(uid);
      _userChangeSubscription?.cancel();
      _userChangeSubscription = doc.snapshots().listen(_onUserChanged);
      _controller?.add(await user());
    }
  }

  void _onUserChanged(DocumentSnapshot<User?> user) {
    if (user.exists) {
      _controller?.add(user.data());
    } else {
      _controller?.add(null);
    }
  }

  void dispose() => _authChanges.removeListener(_onAuthUserChanged);

  static Map<String, Object?> toFirestore(User? user, SetOptions? options) {
    return user?.toJson() ?? {};
  }

  static User? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    try {
      if (!snapshot.exists) {
        return null;
      }
      final json = snapshot.data();
      if (json == null) {
        return null;
      }
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

class UserChanges extends ValueNotifier<User?> {
  UserChanges({
    required UserRepository userRepository,
  }) : super(null) {
    _userChangeSubscription = userRepository.changes.listen((u) {
      value = u;
    });
  }

  StreamSubscription? _userChangeSubscription;

  @override
  void dispose() {
    _userChangeSubscription?.cancel();
    super.dispose();
  }
}

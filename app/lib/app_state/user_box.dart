import 'package:async/async.dart';
import 'package:core/core.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'user_box.models.dart';

class UserBox {
  UserBox({
    required GoogleSignIn googleSignIn,
  }) : _googleSignIn = googleSignIn;

  final GoogleSignIn _googleSignIn;

  late final ReadOnlyStateEntry<GoogleSignInAccount?> googleAccount =
      ReadOnlyStateEntryProxy(
    call: () => _googleSignIn.currentUser,
    changes: () => _googleSignIn.onCurrentUserChanged,
  );
  late final FutureReadOnlyStateEntry<bool> isLoggedIn =
      FutureReadOnlyStateEntryProxy(
    call: () async => _googleSignIn.isSignedIn(),
    changes: () => StreamGroup.mergeBroadcast([
      _googleSignIn.onCurrentUserChanged.map((e) => e != null),
    ]),
  );

  Future<void> init(HiveInterface hive) async {}
}

/// How many times the user signed out since the app started.
///
/// Shared between signing out and asking the provider who the user is: a
/// sign-in check that was out when the user signed out drops its answer rather
/// than taking it — see [UpdateAuth].
class SignOuts() {
  int count = 0;
}

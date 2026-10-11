sealed class AuthenticationException implements Exception {
  const AuthenticationException();
}

class const SignInRequired() extends AuthenticationException {
  @override
  String toString() => 'you are not signed in';
}

class const SignInCancelled() extends AuthenticationException {
  @override
  String toString() => 'signing in was cancelled';
}

class const SignInFailed({
  required final Object cause,
}) extends AuthenticationException {
  @override
  String toString() => 'signing in failed: $cause';
}

class const ProviderUnreachable({
  required final Object cause,
}) extends AuthenticationException {
  @override
  String toString() => 'the sign-in provider could not be reached: $cause';
}

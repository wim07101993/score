import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:score/features/user/behaviours/log_in_with_google.dart';
import 'package:score/features/user/behaviours/login_with_facebook.dart';

part 'log_in_bloc.freezed.dart';

@freezed
class LogInEvent with _$LogInEvent {
  const factory LogInEvent.logInWithGoogle() = _LogInWithGoogle;
  const factory LogInEvent.logInWithFacebook() = _LogInWithFacebook;
}

@freezed
class LogInState with _$LogInState {
  const factory LogInState({
    Failure? failure,
  }) = _Failure;
}

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  LogInBloc({
    required this.logInWithGoogle,
    required this.logInWithFacebook,
  }) : super(const LogInState());

  final LogInWithGoogle logInWithGoogle;
  final LogInWithFacebook logInWithFacebook;

  @override
  Stream<LogInState> mapEventToState(LogInEvent event) {
    return event.when(
      logInWithGoogle: _logInWithGoogle,
      logInWithFacebook: _logInWithFacebook,
    );
  }

  Stream<LogInState> _logInWithGoogle() async* {
    logInWithGoogle();
  }

  Stream<LogInState> _logInWithFacebook() async* {
    logInWithFacebook();
  }
}

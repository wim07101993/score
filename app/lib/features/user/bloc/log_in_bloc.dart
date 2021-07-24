import 'package:bloc/bloc.dart';
import 'package:core/core.dart';

part 'log_in_bloc.freezed.dart';

@freezed
class LogInEvent with _$LogInEvent {
  const factory LogInEvent.logInWithGoogle() = _LogInWithGoogle;
}

@freezed
class LogInState with _$LogInState {
  const factory LogInState({
    Failure? failure,
  }) = _Failure;
}

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  LogInBloc() : super(const LogInState());

  @override
  Stream<LogInState> mapEventToState(LogInEvent event) {
    return event.when(
      logInWithGoogle: logInWithGoogle,
    );
  }

  Stream<LogInState> logInWithGoogle() async* {}
}

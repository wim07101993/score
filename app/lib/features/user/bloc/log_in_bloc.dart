import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:score/data/firebase/user/user.dart';
import 'package:score/features/user/behaviours/log_in_with_google.dart';

part 'log_in_bloc.freezed.dart';

@freezed
class LogInEvent with _$LogInEvent {
  const factory LogInEvent.logInWithGoogle() = _LogInWithGoogle;
  const factory LogInEvent.userChanged() = _UserChanged;
}

@freezed
class LogInState with _$LogInState {
  const factory LogInState({
    User? user,
    Failure? failure,
  }) = _LogInState;
}

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  LogInBloc({
    required this.logInWithGoogle,
    required this.userChanges,
    required this.logger,
  }) : super(const LogInState()) {
    userChanges.addListener(_onUserChanged);
  }

  final Logger logger;
  final LogInWithGoogle logInWithGoogle;
  final UserChanges userChanges;

  @override
  Stream<LogInState> mapEventToState(LogInEvent event) {
    return event.when(
      logInWithGoogle: _logInWithGoogle,
      userChanged: _userChanged,
    );
  }

  Stream<LogInState> _logInWithGoogle() async* {
    final either = await logInWithGoogle();
    if (either is Failed<void>) {
      yield state.copyWith(failure: either.failure);
    }
  }

  Stream<LogInState> _userChanged() async* {
    yield state.copyWith(user: userChanges.value);
  }

  @override
  Future<void> close() {
    userChanges
      ..removeListener(_onUserChanged)
      ..dispose();
    return super.close();
  }

  void _onUserChanged() {
    logger.i('user changed');
    add(const LogInEvent.userChanged());
  }
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_score_bloc.freezed.dart';

@freezed
class CreateScoreEvent with _$CreateScoreEvent {
  const factory CreateScoreEvent.save({
    required String title,
    String? subtitle,
    String? dedication,
    required List<String> composers,
  }) = _CreateScoreEvent;
}

@freezed
class CreateScoreState with _$CreateScoreState {
  const factory CreateScoreState({
    Object? error,
  }) = _CreateScoreState;
}

class CreateScoreBloc extends Bloc<CreateScoreEvent, CreateScoreState> {
  CreateScoreBloc() : super(const CreateScoreState()) {
    on<_CreateScoreEvent>(onCreateScoreEvent);
  }

  FutureOr<void> onCreateScoreEvent(
    _CreateScoreEvent event,
    Emitter<CreateScoreState> emit,
  ) {
    print(event);
  }
}

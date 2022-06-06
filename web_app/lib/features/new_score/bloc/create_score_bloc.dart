import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/features/new_score/models/draft_score.dart';

part 'create_score_bloc.freezed.dart';

@freezed
class CreateScoreEvent with _$CreateScoreEvent {
  const factory CreateScoreEvent.save(DraftScore score) = _CreateScoreEvent;
}

@freezed
class CreateScoreState with _$CreateScoreState {
  const factory CreateScoreState({
    Object? error,
  }) = _CreateScoreState;
}

class CreateScoreBloc extends Bloc<CreateScoreEvent, CreateScoreState> {
  CreateScoreBloc({
    required this.saveNewScore,
  }) : super(const CreateScoreState()) {
    on<_CreateScoreEvent>(onCreateScoreEvent);
  }

  final SaveNewScore saveNewScore;

  Future<void> onCreateScoreEvent(
    _CreateScoreEvent event,
    Emitter<CreateScoreState> emit,
  ) {
    emit(state.copyWith(error: null));
    return saveNewScore(event.score).thenWhen(
      (exception) => emit(state.copyWith(error: exception)),
      (_) {},
    );
  }
}

import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/shared/models/score.dart';

part 'create_score_wizard_bloc.freezed.dart';

@freezed
class CreateScoreWizardEvent with _$CreateScoreWizardEvent {
  const factory CreateScoreWizardEvent.save() = _CreateScoreEvent;
}

@freezed
class CreateScoreWizardState with _$CreateScoreWizardState {
  const factory CreateScoreWizardState({
    Object? error,
    required EditableScore score,
    @Default(false) bool created,
  }) = _CreateScoreState;
}

class CreateScoreWizardBloc
    extends Bloc<CreateScoreWizardEvent, CreateScoreWizardState> {
  CreateScoreWizardBloc({
    required this.saveNewScore,
  }) : super(CreateScoreWizardState(score: EditableScore.empty())) {
    on<_CreateScoreEvent>(onCreateScoreEvent);
  }

  final SaveNewScore saveNewScore;

  Future<void> onCreateScoreEvent(
    _CreateScoreEvent event,
    Emitter<CreateScoreWizardState> emit,
  ) {
    emit(state.copyWith(error: null));
    return saveNewScore(state.score).thenWhen(
      (exception) => emit(state.copyWith(error: exception)),
      (_) => emit(state.copyWith(created: true)),
    );
  }
}

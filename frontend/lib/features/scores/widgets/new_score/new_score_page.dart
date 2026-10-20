import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/scores/widgets/new_score/new_score_body.dart';
import 'package:score/features/scores/widgets/new_score/score_upload_is_for_editors.dart';
import 'package:score/router.dart';

@RoutePage()
class const NewScorePage({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = GetIt.I<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('New score')),
      body: ListenableBuilder(
        listenable: user,
        builder: (context, _) => user.value?.isScoreEditor == true
            ? NewScoreBody(
                onUploaded: (scoreId) =>
                    context.router.replace(ScoreDetailRoute(scoreId: scoreId)),
              )
            : const ScoreUploadIsForEditors(),
      ),
    );
  }
}

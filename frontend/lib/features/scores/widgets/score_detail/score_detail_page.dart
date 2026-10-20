import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_details_body.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/scores/widgets/score_detail/scores_are_for_viewers.dart';
import 'package:score/features/scores/widgets/score_detail/stand/immersive_stand.dart';
import 'package:score/features/scores/widgets/score_detail/stand/stand_actions.dart';

@RoutePage()
class const ScoreDetailPage({
  super.key,
  @PathParam('scoreId') required final String scoreId,
  @QueryParam('isPerforming') final bool? isPerforming,
}) extends StatefulWidget {
  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  final _user = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  late bool _performing = widget.isPerforming ?? false;

  late final _reader = ScoreReader(
    scoreId: widget.scoreId,
  );

  Score? get _score => _scores.getScore(widget.scoreId);

  @override
  void initState() {
    super.initState();
    _reader.open();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reader.load());
  }

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  void _perform() => setState(() => _performing = true);

  void _stopPerforming(bool didPop, Object? _) {
    if (!didPop) setState(() => _performing = false);
  }

  String get _title => _score?.title ?? 'Score';

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: Listenable.merge([
        _user,
        _scores,
        _reader,
      ]),
      builder: (context, _) {
        final user = _user.value;
        final mayView = user != null && user.isScoreViewer;
        final performing = _performing;
        return PopScope(
          canPop: !performing,
          onPopInvokedWithResult: _stopPerforming,
          child: Scaffold(
            appBar: mayView && performing
                ? _standAppBar()
                : AppBar(title: Text(_title)),
            body: _body(user, performing),
          ),
        );
      },
    );
  }

  AppBar _standAppBar() {
    return AppBar(
      toolbarHeight: 48,
      titleSpacing: 0,
      title: Text(_title, overflow: TextOverflow.ellipsis),
      actions: [StandActions(controller: _reader.view)],
    );
  }

  Widget _body(UserInfo? user, bool performing) {
    if (user == null || !user.isScoreViewer) {
      return const ScoresAreForViewers();
    }
    if (performing) {
      return ImmersiveStand(child: ScoreDetailSheet(reader: _reader));
    }
    return ScoreDetailsBody(
      reader: _reader,
      score: _score,
      user: user,
      onPerform: _perform,
    );
  }
}

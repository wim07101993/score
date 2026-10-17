import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/details/pick_music_xml.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_details_body.dart';
import 'package:score/features/scores/widgets/score_detail/models/score_reading_handover.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/scores/widgets/score_detail/score_upload_is_for_editors.dart';
import 'package:score/features/scores/widgets/score_detail/scores_are_for_viewers.dart';
import 'package:score/features/scores/widgets/score_detail/stand/stand_actions.dart';
import 'package:score/router.dart';

class const ScoreDetailPage({
  super.key,
  required final String? scoreId,
  final bool performing = false,
  final ScoreReadingHandover? handover,
}) extends StatefulWidget {
  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

class _ScoreDetailPageState extends State<ScoreDetailPage> {
  final _user = GetIt.I<AuthNotifier>();

  late final _reader = ScoreReader(
    scoreId: _isNew || _isPaper ? null : widget.scoreId,
    performing: widget.performing,
    handover: widget.handover,
  );

  bool get _isNew => widget.scoreId == null;
  bool get _isPaper => widget.scoreId == Score.paperId;

  @override
  void initState() {
    super.initState();
    _reader.open();
    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reader.load());
    }
  }

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  /// Puts the score on the whole screen, read the way it is being read here.
  void _perform() {
    final scoreId = widget.scoreId;
    if (scoreId == null) {
      return;
    }
    context.router.push(
      PerformScoreRoute(
        scoreId: scoreId,
        handover: _reader.handOver(),
      ),
    );
  }

  String get _title {
    if (_isNew) return 'New score';
    if (_isPaper) return 'Played from paper';
    return _reader.score?.title ?? 'Score';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 0,
        title: Text(_title, overflow: TextOverflow.ellipsis),
        actions: [StandActions(reader: _reader)],
      ),
      body: ValueListenableBuilder(
        valueListenable: _user,
        builder: (context, user, _) {
          if (user == null || !user.isScoreViewer) {
            return const ScoresAreForViewers();
          }
          if (_isNew && !user.isScoreEditor) {
            return const ScoreUploadIsForEditors();
          }
          return ScoreDetailsBody();
        },
      ),
    );
  }

  Widget _landscapeBody(UserInfo user) {
    return Row(
      children: [
        ScoreAbout(
          scoreProperties: null,
          scoreData: null,
          user: null,
          viewController: null,
        ),
      ],
    );
  }

  Widget _portraitBody(UserInfo user) {}

  Widget _body(UserInfo user, BoxConstraints constraints) {
    final sheet = ScoreDetailSheet(reader: _reader, isPaper: _isPaper);
    if (widget.performing) return sheet;
    return ScoreDetailsBody(
      about: ScoreAbout(
        reader: _reader,
        onPerform: _perform,
        mayUpload: user.isScoreEditor == true && !_isPaper,
      ),
      sheet: sheet,
    );
  }
}

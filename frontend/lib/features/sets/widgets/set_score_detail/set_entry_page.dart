import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/widgets/set_score_detail/set_score_detail_page.dart';

@RoutePage()
class const SetEntryPage({
  super.key,
  @PathParam('setId') required final String setId,
  @PathParam('entryId') required final String entryId,
  @QueryParam('isPerforming') final bool? isPerforming,
}) extends StatefulWidget {
  @override
  State<SetEntryPage> createState() => _SetEntryPageState();
}

class _SetEntryPageState extends State<SetEntryPage> {
  final _sets = GetIt.I<SetsNotifier>();

  ScoreSet? _set;
  bool _reading = true;

  @override
  void initState() {
    super.initState();
    _sets.addListener(_takeSetChanges);
    _readSet();
  }

  @override
  void dispose() {
    _sets.removeListener(_takeSetChanges);
    super.dispose();
  }

  Future<void> _readSet() async {
    final set = (await GetIt.I<GetSet>()(widget.setId)).valueOrNull;
    if (!mounted) return;
    setState(() {
      _set = set;
      _reading = false;
    });
  }

  SetEntry? _entryOf(ScoreSet? set) =>
      set?.entries.where((entry) => entry.id == widget.entryId).firstOrNull;

  void _takeSetChanges() {
    if (_reading) return;
    final now = _sets.getSet(widget.setId);
    final entry = _entryOf(now);
    final shown = _entryOf(_set);
    if (entry == null || (shown != null && entry.scoreId == shown.scoreId)) {
      return;
    }
    setState(() => _set = now);
  }

  @override
  Widget build(BuildContext context) {
    if (_reading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return SetScoreDetailPage(
      key: ObjectKey(_set),
      set: _set,
      entryId: widget.entryId,
      isPerforming: widget.isPerforming ?? false,
    );
  }
}

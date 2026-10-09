import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/behaviours/update_auth.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/sync/behaviours/update_collections.dart';
import 'package:score/features/sync/behaviours/update_scores.dart';
import 'package:score/features/sync/behaviours/update_sets.dart';

/// Asks the provider who the user is behind a page that is already showing,
/// and then fetches what a page drawn before there was anyone to fetch it for
/// did not: a page asks for its sync once, when it is opened, and a user who
/// only became a reader of scores after that would otherwise wait for the
/// next page to be opened.
class UpdateAuthAndCatchUp({
  super.monitor,
  required final OidcApi oidc,
  required final UpdateAuth updateAuth,
  required final UpdateScores updateScores,
  required final UpdateSets updateSets,
  required final UpdateCollections updateCollections,
}) extends Behaviour<UpdateAuthParams, void> {
  @override
  String get description => 'catching up with who the user is';

  @override
  Future<void> action(UpdateAuthParams input, BehaviourTrack? track) async {
    final couldView = (await oidc.keptUserInfo())?.isScoreViewer == true;
    final user = await updateAuth.action(input, track);
    if (couldView || user?.isScoreViewer != true) {
      return;
    }
    await updateScores.action(track);
    await updateSets.action(track);
    await updateCollections.action(track);
  }
}

import 'package:score/features/sets/models.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/error_extensions.dart';
import 'package:score_api/score_api.dart' as api;
import 'package:tonik_util/tonik_util.dart';

/// The sets endpoints of the API.
///
/// Unlike the scores endpoints, these are written to as well as read from, and
/// a write is made from an edit that was already accepted and stored on this
/// device. So a failure has to say more than that it failed: whether the write
/// is worth trying again decides between keeping the edit queued and giving it
/// up, and that is what [ApiException.isWorthRetrying] says.
class const SetsApi({
  required final ApiClientFactory clientFactory,
}) {
  /// The generated client, sending the token of the moment.
  api.SetsApi get _api => clientFactory.build(api.SetsApi.new);

  /// The sets that changed within the window, the caller's own and the ones
  /// shared with them. Sets that were deleted within it come back too, with
  /// `deleted_at` filled in.
  Future<List<ScoreSet>> listSets(
    DateTime? changesSince,
    DateTime? changesUntil,
  ) async {
    final result = await _api.listSets(
      changesSince: changesSince ?? DateTime.utc(1970),
      changesUntil: changesUntil ?? DateTime.now(),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.ListSetsResponse200(:final body) =>
          body.map((el) => el.toScoreSet()).toList(growable: false),
        api.ListSetsResponse400(:final body) => throw body.toApiException(),
        api.ListSetsResponse401(:final body) => throw body.toApiException(),
        api.ListSetsResponse403(:final body) => throw body.toApiException(),
        api.ListSetsResponseDefault(:final body) => throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// One set, asked for by id. `null` when there is no such set, or when it is
  /// neither the caller's nor shared with them.
  Future<ScoreSet?> getSet(String setId) async {
    final result = await _api.getSet(setId: setId);
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.GetSetResponse200(:final body) => body.toScoreSet(),
        api.GetSetResponse404(:final body)
            when body.errorCode == ErrorCode.setNotFound =>
          null,
        api.GetSetResponse400(:final body) => throw body.toApiException(),
        api.GetSetResponse401(:final body) => throw body.toApiException(),
        api.GetSetResponse403(:final body) => throw body.toApiException(),
        api.GetSetResponse404(:final body) => throw body.toApiException(),
        api.GetSetResponseDefault(:final body) => throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Stores what the set is — the gig, and who may read it — and hands back the
  /// set as it now reads.
  ///
  /// What is played in it is not written here and is not touched by writing
  /// here: an entry is a resource of its own, put into the set and taken out
  /// again one at a time. So a set is created empty and filled afterwards, and
  /// correcting a title never restates the running order.
  Future<ScoreSet> putSet(
    String setId,
    Map<String, Object?> writeSet,
  ) async {
    final result = await _api.putSet(
      setId: setId,
      body: api.WriteSet.fromJson(writeSet),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutSetResponse200(:final body) => body.toScoreSet(),
        api.PutSetResponse400(:final body) => throw body.toApiException(),
        api.PutSetResponse401(:final body) => throw body.toApiException(),
        api.PutSetResponse403(:final body) => throw body.toApiException(),
        api.PutSetResponse413(:final body) => throw body.toApiException(),
        api.PutSetResponse415(:final body) => throw body.toApiException(),
        api.PutSetResponseDefault(:final body) => throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Puts one score into a set, or changes how it is played, and hands the
  /// entry back as it now reads — including where in the running order it
  /// ended up.
  Future<({SetEntry entry, int? position})> putEntry(
    String setId,
    String entryId,
    Map<String, Object?> writeEntry,
  ) async {
    final result = await _api.putSetEntry(
      setId: setId,
      entryId: entryId,
      body: api.WriteSetEntry.fromJson(writeEntry),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutSetEntryResponse200(:final body) => (
          entry: body.toSetEntry(),
          position: body.position,
        ),
        api.PutSetEntryResponse400(:final body) => throw body.toApiException(),
        api.PutSetEntryResponse401(:final body) => throw body.toApiException(),
        api.PutSetEntryResponse403(:final body) => throw body.toApiException(),
        api.PutSetEntryResponse404(:final body) => throw body.toApiException(),
        api.PutSetEntryResponse413(:final body) => throw body.toApiException(),
        api.PutSetEntryResponse415(:final body) => throw body.toApiException(),
        api.PutSetEntryResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Takes one score out of a set. An entry that is already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteEntry(
    String setId,
    String entryId,
  ) async {
    final result = await _api.deleteSetEntry(
      setId: setId,
      entryId: entryId,
    );
    switch (result) {
      case TonikSuccess(:final value):
        switch (value) {
          case api.DeleteSetEntryResponse204():
            return;
          // Gone already: what was asked for is the state it is now in.
          case api.DeleteSetEntryResponse404(:final body)
              when body.errorCode == ErrorCode.setNotFound ||
                  body.errorCode == ErrorCode.setEntryNotFound:
            return;
          case api.DeleteSetEntryResponse400(:final body):
            throw body.toApiException();
          case api.DeleteSetEntryResponse401(:final body):
            throw body.toApiException();
          case api.DeleteSetEntryResponse403(:final body):
            throw body.toApiException();
          case api.DeleteSetEntryResponse404(:final body):
            throw body.toApiException();
          case api.DeleteSetEntryResponseDefault(:final body):
            throw body.toApiException();
        }
      case TonikError():
        throw result.toApiException();
    }
  }

  /// Stores how the caller looks at one entry of a set.
  ///
  /// Anyone who can read the set can write their own view of its entries: it
  /// says nothing about the set and changes nothing anybody else sees, so a
  /// player who cannot change a note of the running order can still say how
  /// they read it.
  Future<EntryView> putEntryView(
    String setId,
    String entryId,
    Map<String, Object?> writeView,
  ) async {
    final result = await _api.putSetEntryView(
      setId: setId,
      entryId: entryId,
      body: api.WriteEntryView.fromJson(writeView),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutSetEntryViewResponse200(:final body) => body.toEntryView(),
        api.PutSetEntryViewResponse400(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponse401(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponse403(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponse404(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponse413(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponse415(:final body) =>
          throw body.toApiException(),
        api.PutSetEntryViewResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Marks the set as deleted. A set that was already gone is not an error.
  Future<void> deleteSet(String setId) async {
    final result = await _api.deleteSet(setId: setId);
    switch (result) {
      case TonikSuccess(:final value):
        switch (value) {
          case api.DeleteSetResponse204():
            return;
          // Gone already: what was asked for is the state it is now in.
          case api.DeleteSetResponse404(:final body)
              when body.errorCode == ErrorCode.setNotFound ||
                  body.errorCode == ErrorCode.setEntryNotFound:
            return;
          case api.DeleteSetResponse400(:final body):
            throw body.toApiException();
          case api.DeleteSetResponse401(:final body):
            throw body.toApiException();
          case api.DeleteSetResponse403(:final body):
            throw body.toApiException();
          case api.DeleteSetResponse404(:final body):
            throw body.toApiException();
          case api.DeleteSetResponseDefault(:final body):
            throw body.toApiException();
        }
      case TonikError():
        throw result.toApiException();
    }
  }

  Future<bool> canBeReached() => clientFactory.canBeReached();
}

extension on api.Set {
  /// This set as this app knows one, with nothing owed and nothing said yet
  /// about when this device heard of it.
  ScoreSet toScoreSet() => ScoreSet(
    id: id,
    title: title,
    description: description,
    entries: entries.map((el) => el.toSetEntry()).toList(growable: false),
    sharedWith: sharedWith,
    isOwner: isOwner,
    lastChangedAt: lastChangedAt,
    deletedAt: deletedAt,
  );
}

extension on api.SetEntry {
  SetEntry toSetEntry() => SetEntry(
    id: id,
    scoreId: scoreIdOf(scoreId),
    description: description,
    transposition: transpositionOf(transposition),
    view: view.toEntryView(),
    // Everything the API hands over is on the server by definition.
    synced: true,
  );
}

extension on api.EntryView {
  EntryView toEntryView() => EntryView(
    transposition: transpositionOf(transposition),
    hiddenParts: hiddenParts,
    zoom: zoomOf(zoom),
  );
}

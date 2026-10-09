import 'package:score/features/collections/models.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/error_extensions.dart';
import 'package:score_api/score_api.dart' as api;
import 'package:tonik_util/tonik_util.dart';

/// The collections endpoints of the API.
///
/// Everything about talking to the server is the same as it is for a set, for
/// the same reason: a write is made from an edit that was already accepted and
/// stored on this device, so a failure has to say more than that it failed.
/// Whether the write is worth trying again decides between keeping the edit
/// queued and giving it up, and that is what [ApiException.isWorthRetrying]
/// says.
class const CollectionsApi({
  required final ApiClientFactory clientFactory,
}) {
  /// The generated client, sending the token of the moment.
  api.CollectionsApi get _api => clientFactory.build(api.CollectionsApi.new);

  /// The collections that changed within the window, the caller's own and the
  /// ones shared with them. Collections that were deleted within it come back
  /// too, with `deleted_at` filled in.
  Future<List<Collection>> listCollections(
    DateTime? changesSince,
    DateTime? changesUntil,
  ) async {
    final result = await _api.listCollections(
      changesSince: changesSince ?? DateTime.utc(1970),
      changesUntil: changesUntil ?? DateTime.now(),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.ListCollectionsResponse200(:final body) =>
          body.map((el) => el.toCollection()).toList(growable: false),
        api.ListCollectionsResponse400(:final body) =>
          throw body.toApiException(),
        api.ListCollectionsResponse401(:final body) =>
          throw body.toApiException(),
        api.ListCollectionsResponse403(:final body) =>
          throw body.toApiException(),
        api.ListCollectionsResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// One collection, asked for by id. `null` when there is no such collection,
  /// or when it is neither the caller's nor shared with them.
  Future<Collection?> getCollection(
    String collectionId,
  ) async {
    final result = await _api.getCollection(collectionId: collectionId);
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.GetCollectionResponse200(:final body) => body.toCollection(),
        api.GetCollectionResponse404(:final body)
            when body.errorCode == ErrorCode.collectionNotFound =>
          null,
        api.GetCollectionResponse400(:final body) =>
          throw body.toApiException(),
        api.GetCollectionResponse401(:final body) =>
          throw body.toApiException(),
        api.GetCollectionResponse403(:final body) =>
          throw body.toApiException(),
        api.GetCollectionResponse404(:final body) =>
          throw body.toApiException(),
        api.GetCollectionResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Stores what the collection is — the group of pieces, and who may read it —
  /// and hands back the collection as it now reads. What is in it is written
  /// one piece at a time, the same way a set's songs are.
  Future<Collection> putCollection(
    String collectionId,
    Map<String, Object?> writeCollection,
  ) async {
    final result = await _api.putCollection(
      collectionId: collectionId,
      body: api.WriteCollection.fromJson(writeCollection),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutCollectionResponse200(:final body) => body.toCollection(),
        api.PutCollectionResponse400(:final body) =>
          throw body.toApiException(),
        api.PutCollectionResponse401(:final body) =>
          throw body.toApiException(),
        api.PutCollectionResponse403(:final body) =>
          throw body.toApiException(),
        api.PutCollectionResponse413(:final body) =>
          throw body.toApiException(),
        api.PutCollectionResponse415(:final body) =>
          throw body.toApiException(),
        api.PutCollectionResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Puts one piece into a collection, or changes what the group does with it,
  /// and hands the entry back as it now reads.
  Future<CollectionEntry> putEntry(
    String collectionId,
    String entryId,
    Map<String, Object?> writeEntry,
  ) async {
    final result = await _api.putCollectionEntry(
      collectionId: collectionId,
      entryId: entryId,
      body: api.WriteCollectionEntry.fromJson(writeEntry),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutCollectionEntryResponse200(:final body) =>
          body.toCollectionEntry(),
        api.PutCollectionEntryResponse400(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse401(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse403(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse404(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse409(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse413(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponse415(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Takes one piece out of a collection. One that is already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteEntry(
    String collectionId,
    String entryId,
  ) async {
    final result = await _api.deleteCollectionEntry(
      collectionId: collectionId,
      entryId: entryId,
    );
    switch (result) {
      case TonikSuccess(:final value):
        switch (value) {
          case api.DeleteCollectionEntryResponse204():
            return;
          // Gone already: what was asked for is the state it is now in.
          case api.DeleteCollectionEntryResponse404(:final body)
              when body.errorCode == ErrorCode.collectionNotFound ||
                  body.errorCode == ErrorCode.collectionEntryNotFound:
            return;
          case api.DeleteCollectionEntryResponse400(:final body):
            throw body.toApiException();
          case api.DeleteCollectionEntryResponse401(:final body):
            throw body.toApiException();
          case api.DeleteCollectionEntryResponse403(:final body):
            throw body.toApiException();
          case api.DeleteCollectionEntryResponse404(:final body):
            throw body.toApiException();
          case api.DeleteCollectionEntryResponseDefault(:final body):
            throw body.toApiException();
        }
      case TonikError():
        throw result.toApiException();
    }
  }

  /// Stores how the caller looks at one entry of a collection.
  ///
  /// Anyone who can read the collection can write their own view of its
  /// entries: it says nothing about the collection and changes nothing anybody
  /// else sees, so a player who cannot add a piece to the book can still say
  /// how they read one that is in it.
  Future<EntryView> putEntryView(
    String collectionId,
    String entryId,
    Map<String, Object?> writeView,
  ) async {
    final result = await _api.putCollectionEntryView(
      collectionId: collectionId,
      entryId: entryId,
      body: api.WriteEntryView.fromJson(writeView),
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.PutCollectionEntryViewResponse200(:final body) =>
          body.toEntryView(),
        api.PutCollectionEntryViewResponse400(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponse401(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponse403(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponse404(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponse413(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponse415(:final body) =>
          throw body.toApiException(),
        api.PutCollectionEntryViewResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// Marks the collection as deleted. One that was already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteCollection(String collectionId) async {
    final result = await _api.deleteCollection(
      collectionId: collectionId,
    );
    switch (result) {
      case TonikSuccess(:final value):
        switch (value) {
          case api.DeleteCollectionResponse204():
            return;
          // Gone already: what was asked for is the state it is now in.
          case api.DeleteCollectionResponse404(:final body)
              when body.errorCode == ErrorCode.collectionNotFound ||
                  body.errorCode == ErrorCode.collectionEntryNotFound:
            return;
          case api.DeleteCollectionResponse400(:final body):
            throw body.toApiException();
          case api.DeleteCollectionResponse401(:final body):
            throw body.toApiException();
          case api.DeleteCollectionResponse403(:final body):
            throw body.toApiException();
          case api.DeleteCollectionResponse404(:final body):
            throw body.toApiException();
          case api.DeleteCollectionResponseDefault(:final body):
            throw body.toApiException();
        }
      case TonikError():
        throw result.toApiException();
    }
  }

  Future<bool> canBeReached() => clientFactory.canBeReached();
}

extension on api.Collection {
  /// This collection as this app knows one, with nothing owed and nothing said
  /// yet about when this device heard of it.
  Collection toCollection() => Collection(
    id: id,
    title: title,
    description: description,
    entries: entries
        .map((el) => el.toCollectionEntry())
        .toList(growable: false),
    sharedWith: sharedWith,
    isOwner: isOwner,
    lastChangedAt: lastChangedAt,
    deletedAt: deletedAt,
  );
}

extension on api.CollectionEntry {
  CollectionEntry toCollectionEntry() => CollectionEntry(
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

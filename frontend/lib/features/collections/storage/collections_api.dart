import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sync/models/syncable.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/error_extensions.dart';
import 'package:score_api/score_api.dart' as api;
import 'package:tonik_util/tonik_util.dart';

class const CollectionsApi({
  required final ApiClientFactory clientFactory,
}) implements SyncApi<Collection> {
  api.CollectionsApi get _api => clientFactory.build(api.CollectionsApi.new);

  @override
  Future<SyncChanges<Collection>> listChanges({
    required DateTime since,
    DateTime? until,
  }) async {
    final result = await _api.listCollections(
      changesSince: since,
      changesUntil: until ?? endOfTime,
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.ListCollectionsResponse200(:final body) => (
          changed: body
              .whereType<api.ListedCollectionCollection>()
              .map((el) => el.value.toCollection())
              .toList(growable: false),
          deleted: body
              .whereType<api.ListedCollectionDeletedResource>()
              .map(
                (el) => DeletedEntity(
                  id: el.value.id,
                  deletedAt: el.value.deletedAt,
                ),
              )
              .toList(growable: false),
        ),
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

  Future<Collection?> getCollection(String collectionId) async {
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

  Future<ScoreViewSettings> putEntryView(
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
          body.toScoreViewSettings(),
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

  @override
  Future<bool> canBeReached() => clientFactory.canBeReached();
}

extension on api.Collection {
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
  );
}

extension on api.CollectionEntry {
  CollectionEntry toCollectionEntry() => CollectionEntry(
    id: id,
    scoreId: scoreIdOf(scoreId),
    description: description,
    transposition: transposition,
    view: view.toScoreViewSettings(),
  );
}

extension on api.EntryView {
  ScoreViewSettings toScoreViewSettings() => ScoreViewSettings(
    transposition: transposition,
    hiddenParts: hiddenParts,
    zoom: zoom,
  );
}

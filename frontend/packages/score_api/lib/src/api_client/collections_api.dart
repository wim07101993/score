// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i9;

import 'package:http/http.dart' as _i12;
import 'package:score_api/src/model/write_collection.dart' as _i15;
import 'package:score_api/src/model/write_collection_entry.dart' as _i18;
import 'package:score_api/src/model/write_entry_view.dart' as _i21;
import 'package:score_api/src/operation/delete_collection.dart' as _i5;
import 'package:score_api/src/operation/delete_collection_entry.dart' as _i7;
import 'package:score_api/src/operation/get_collection.dart' as _i3;
import 'package:score_api/src/operation/list_collections.dart' as _i2;
import 'package:score_api/src/operation/put_collection.dart' as _i4;
import 'package:score_api/src/operation/put_collection_entry.dart' as _i6;
import 'package:score_api/src/operation/put_collection_entry_view.dart' as _i8;
import 'package:score_api/src/response_wrapper/delete_collection_entry_response.dart'
    as _i19;
import 'package:score_api/src/response_wrapper/delete_collection_response.dart'
    as _i16;
import 'package:score_api/src/response_wrapper/get_collection_response.dart'
    as _i13;
import 'package:score_api/src/response_wrapper/list_collections_response.dart'
    as _i11;
import 'package:score_api/src/response_wrapper/put_collection_entry_response.dart'
    as _i17;
import 'package:score_api/src/response_wrapper/put_collection_entry_view_response.dart'
    as _i20;
import 'package:score_api/src/response_wrapper/put_collection_response.dart'
    as _i14;
import 'package:score_api/src/server/server.dart' as _i1;
import 'package:tonik_util/tonik_util.dart' as _i10;

/// The unordered groups of scores that belong together: a book, a band's
/// repertoire.
///
class CollectionsApi {
  CollectionsApi(_i1.Server server)
    : _listCollections = _i2.ListCollections(
        server.baseUrl,
        () => server.client,
      ),
      _getCollection = _i3.GetCollection(server.baseUrl, () => server.client),
      _putCollection = _i4.PutCollection(server.baseUrl, () => server.client),
      _deleteCollection = _i5.DeleteCollection(
        server.baseUrl,
        () => server.client,
      ),
      _putCollectionEntry = _i6.PutCollectionEntry(
        server.baseUrl,
        () => server.client,
      ),
      _deleteCollectionEntry = _i7.DeleteCollectionEntry(
        server.baseUrl,
        () => server.client,
      ),
      _putCollectionEntryView = _i8.PutCollectionEntryView(
        server.baseUrl,
        () => server.client,
      );

  final _i2.ListCollections _listCollections;

  final _i3.GetCollection _getCollection;

  final _i4.PutCollection _putCollection;

  final _i5.DeleteCollection _deleteCollection;

  final _i6.PutCollectionEntry _putCollectionEntry;

  final _i7.DeleteCollectionEntry _deleteCollectionEntry;

  final _i8.PutCollectionEntryView _putCollectionEntryView;

  /// List the collections that changed within a window.
  /// Returns every collection the caller owns or that is shared with them whose
  /// last change falls within the given window, most recently changed first. Both
  /// ends of the window are inclusive and both are required: a client
  /// synchronises by asking for everything since the moment it last asked.
  ///
  /// Collections that were deleted within the window are returned too, as
  /// nothing but their id and `deleted_at`, so that a client holding a copy
  /// learns that it is gone rather than syncing it back.
  ///
  /// Requires the `score_viewer` role. A collection names scores but changes
  /// nothing about them, so keeping one asks no more of a user than reading the
  /// scores in it.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [changesSince] The start of the change window, inclusive.
  /// [changesUntil] The end of the change window, inclusive.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  ///
  /// Parameter examples:
  /// [changesSince]:
  /// **Example**:
  /// ```
  /// 2024-01-01T00:00:00Z
  /// ```
  ///
  /// [changesUntil]:
  /// **Example**:
  /// ```
  /// 2024-01-01T00:00:00Z
  /// ```
  _i9.Future<_i10.TonikResult<_i11.ListCollectionsResponse, _i12.Response>>
  listCollections({
    required _i9.DateTime changesSince,
    required _i9.DateTime changesUntil,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _listCollections(
    changesSince: changesSince,
    changesUntil: changesUntil,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Fetch a single collection.
  /// Returns the collection, whether the caller owns it or it is shared with
  /// them. `is_owner` says which of the two it is, and `shared_with` is only
  /// filled in for the owner.
  ///
  /// The pieces come back by title. A collection has no order of its own, so that
  /// is not one: it is the order a list somebody is looking through should be in.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i13.GetCollectionResponse, _i12.Response>>
  getCollection({
    required _i9.String collectionId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _getCollection(
    collectionId: collectionId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Create or replace a collection.
  /// Stores the collection under the given id, replacing whatever was stored
  /// under it before, and returns it as it now reads. A collection that is not
  /// there yet belongs to whoever creates it; one that is can only be written by
  /// its owner.
  ///
  /// What is in the collection is not written here and is not touched by writing
  /// here: an entry is a resource of its own, so a collection is created empty
  /// and filled afterwards.
  ///
  /// Writing a collection that had been deleted brings it back, empty: a client that
  /// still has it and edits it is saying it should exist.
  ///
  /// Requires the `score_viewer` role. A collection names scores but changes
  /// nothing about them, so building one asks no more of a user than reading the
  /// scores in it.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i14.PutCollectionResponse, _i12.Response>>
  putCollection({
    required _i15.WriteCollection body,
    required _i9.String collectionId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putCollection(
    body: body,
    collectionId: collectionId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Delete a collection.
  /// Deletes the collection: its pieces, its shares and how anybody reads them
  /// are removed. Its id is kept, with when it was deleted, its owner and who it
  /// was shared with, and it keeps turning up in their change windows as nothing
  /// but its id and `deleted_at`, so that a client holding a copy learns that it
  /// is gone. Fetching it by id answers 404.
  ///
  /// Only the owner of a collection can delete it. A collection that is not
  /// there, already deleted, or not the caller's is answered the same way.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i16.DeleteCollectionResponse, _i12.Response>>
  deleteCollection({
    required _i9.String collectionId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _deleteCollection(
    collectionId: collectionId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Put one piece into a collection, or change what the group does with it.
  /// Stores the entry under the given id and returns it as it now reads,
  /// including how the caller looks at it.
  ///
  /// A collection holds a piece once. An entry naming a score that is already in
  /// the collection under a different entry is refused, and the refusal names the
  /// entry it is already in — a client that has just been told a piece is in the
  /// book wants that page, not a second copy of it. Writing the entry the score
  /// is already in is not that: it is saying what the group does with a piece the
  /// collection already has, which is what an entry is for.
  ///
  /// An entry is its own resource because a collection is not rewritten to change
  /// one piece in it: a client that added a piece sends that piece, and a client
  /// that is catching up after a while offline sends what it changed rather than
  /// a collection that may have moved on without it.
  ///
  /// The id is the client's to name, which is what lets a player put a piece in
  /// and say how they read it before either has reached the server. An id that
  /// already belongs to an entry of another collection is refused rather than
  /// taken over: it would point this collection's entry at what another
  /// collection's players said about theirs.
  ///
  /// Only the owner of a collection can write its entries: what is in it is the
  /// collection, and the collection is theirs. How anybody reads it is not — that
  /// is `/collections/{collectionId}/entries/{entryId}/view`, which everyone the
  /// collection is shared with writes for themselves.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i17.PutCollectionEntryResponse, _i12.Response>>
  putCollectionEntry({
    required _i18.WriteCollectionEntry body,
    required _i9.String collectionId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putCollectionEntry(
    body: body,
    collectionId: collectionId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Take one piece out of a collection.
  /// Removes the entry. What every player said about how they look at it goes
  /// with it: it was about a piece that is no longer in the collection.
  ///
  /// Unlike a collection, an entry is removed rather than kept as a headstone. A
  /// client that is holding a copy learns it is gone from the collection it is
  /// in, which it reads whole.
  ///
  /// Only the owner of a collection can take an entry out of it. An entry that is
  /// not there, is not in the collection that was named, or is in a collection
  /// the caller cannot read, are all answered the same way.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<
    _i10.TonikResult<_i19.DeleteCollectionEntryResponse, _i12.Response>
  >
  deleteCollectionEntry({
    required _i9.String collectionId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _deleteCollectionEntry(
    collectionId: collectionId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Say how you look at one entry of a collection.
  /// Stores the caller's own view of this entry, replacing whatever they had said
  /// before, and returns it as it now reads.
  ///
  /// Anyone who can read the collection can write their own view of its entries:
  /// it says nothing about the collection and changes nothing anybody else sees,
  /// so it asks no more of a player than reading the collection does. Being the
  /// owner is neither needed nor enough to write somebody else's — there is no
  /// way to write a view that is not your own.
  ///
  /// A collection the caller cannot read, and an entry that is not in the
  /// collection named, are answered the same way as one that is not there at all.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [collectionId] The id the collection is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<
    _i10.TonikResult<_i20.PutCollectionEntryViewResponse, _i12.Response>
  >
  putCollectionEntryView({
    required _i21.WriteEntryView body,
    required _i9.String collectionId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putCollectionEntryView(
    body: body,
    collectionId: collectionId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );
}

// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i9;

import 'package:http/http.dart' as _i12;
import 'package:score_api/src/model/write_entry_view.dart' as _i21;
import 'package:score_api/src/model/write_set.dart' as _i15;
import 'package:score_api/src/model/write_set_entry.dart' as _i18;
import 'package:score_api/src/operation/delete_set.dart' as _i5;
import 'package:score_api/src/operation/delete_set_entry.dart' as _i7;
import 'package:score_api/src/operation/get_set.dart' as _i3;
import 'package:score_api/src/operation/list_sets.dart' as _i2;
import 'package:score_api/src/operation/put_set.dart' as _i4;
import 'package:score_api/src/operation/put_set_entry.dart' as _i6;
import 'package:score_api/src/operation/put_set_entry_view.dart' as _i8;
import 'package:score_api/src/response_wrapper/delete_set_entry_response.dart'
    as _i19;
import 'package:score_api/src/response_wrapper/delete_set_response.dart'
    as _i16;
import 'package:score_api/src/response_wrapper/get_set_response.dart' as _i13;
import 'package:score_api/src/response_wrapper/list_sets_response.dart' as _i11;
import 'package:score_api/src/response_wrapper/put_set_entry_response.dart'
    as _i17;
import 'package:score_api/src/response_wrapper/put_set_entry_view_response.dart'
    as _i20;
import 'package:score_api/src/response_wrapper/put_set_response.dart' as _i14;
import 'package:score_api/src/server/server.dart' as _i1;
import 'package:tonik_util/tonik_util.dart' as _i10;

/// The ordered lists of scores a gig is played from.
class SetsApi {
  SetsApi(_i1.Server server)
    : _listSets = _i2.ListSets(server.baseUrl, () => server.client),
      _getSet = _i3.GetSet(server.baseUrl, () => server.client),
      _putSet = _i4.PutSet(server.baseUrl, () => server.client),
      _deleteSet = _i5.DeleteSet(server.baseUrl, () => server.client),
      _putSetEntry = _i6.PutSetEntry(server.baseUrl, () => server.client),
      _deleteSetEntry = _i7.DeleteSetEntry(server.baseUrl, () => server.client),
      _putSetEntryView = _i8.PutSetEntryView(
        server.baseUrl,
        () => server.client,
      );

  final _i2.ListSets _listSets;

  final _i3.GetSet _getSet;

  final _i4.PutSet _putSet;

  final _i5.DeleteSet _deleteSet;

  final _i6.PutSetEntry _putSetEntry;

  final _i7.DeleteSetEntry _deleteSetEntry;

  final _i8.PutSetEntryView _putSetEntryView;

  /// List the sets that changed within a window.
  /// Returns every set the caller owns or that is shared with them whose last
  /// change falls within the given window, most recently changed first. Both
  /// ends of the window are inclusive and both are required: a client
  /// synchronises by asking for everything since the moment it last asked.
  ///
  /// Sets that were deleted within the window are returned too, with
  /// `deleted_at` filled in, so that a client holding a copy learns that it is
  /// gone rather than syncing it back.
  ///
  /// Requires the `score_viewer` role. A set names scores but changes nothing
  /// about them, so keeping one asks no more of a user than reading the scores
  /// in it.
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
  _i9.Future<_i10.TonikResult<_i11.ListSetsResponse, _i12.Response>> listSets({
    required _i9.DateTime changesSince,
    required _i9.DateTime changesUntil,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _listSets(
    changesSince: changesSince,
    changesUntil: changesUntil,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Fetch a single set.
  /// Returns the set, whether the caller owns it or it is shared with them.
  /// `is_owner` says which of the two it is, and `shared_with` is only filled in
  /// for the owner.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i13.GetSetResponse, _i12.Response>> getSet({
    required _i9.String setId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _getSet(
    setId: setId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Create or replace a set.
  /// Stores the set under the given id, replacing whatever was stored under it
  /// before, and returns it as it now reads. A set that is not there yet belongs
  /// to whoever creates it; one that is can only be written by its owner.
  ///
  /// Writing a set that had been deleted brings it back: a client that still has
  /// it and edits it is saying it should exist.
  ///
  /// Requires the `score_viewer` role. A set names scores but changes nothing
  /// about them, so building one asks no more of a user than reading the scores
  /// in it.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i14.PutSetResponse, _i12.Response>> putSet({
    required _i15.WriteSet body,
    required _i9.String setId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putSet(
    body: body,
    setId: setId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Delete a set.
  /// Marks the set as deleted. It is kept rather than removed, and it keeps
  /// turning up in the change window with `deleted_at` filled in, so that a
  /// client holding a copy learns that it is gone.
  ///
  /// Only the owner of a set can delete it. A set that is not there, already
  /// deleted, or not the caller's is answered the same way.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i16.DeleteSetResponse, _i12.Response>>
  deleteSet({
    required _i9.String setId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _deleteSet(
    setId: setId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Put one score into a set, or change how it is played.
  /// Stores the entry under the given id and returns it as it now reads,
  /// including where in the running order it ended up and how the caller looks
  /// at it.
  ///
  /// An entry is its own resource because a set is not rewritten to change one
  /// song in it: a client that added a song sends that song, and a client that
  /// is catching up after a gig it spent offline sends the songs it changed
  /// rather than a running order that may have moved on without it.
  ///
  /// The id is the client's to name, and naming it is what lets a player say how
  /// they read a song before either has reached the server. An id that already
  /// belongs to an entry of another set is refused rather than taken over: it
  /// would point this set's entry at what another set's players said about
  /// theirs.
  ///
  /// Only the owner of a set can write its entries: what the band plays is the
  /// set, and the set is theirs. How anybody reads it is not — that is
  /// `/sets/{setId}/entries/{entryId}/view`, which everyone the set is shared
  /// with writes for themselves.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i17.PutSetEntryResponse, _i12.Response>>
  putSetEntry({
    required _i18.WriteSetEntry body,
    required _i9.String setId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putSetEntry(
    body: body,
    setId: setId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Take one score out of a set.
  /// Removes the entry and closes the running order up around it. What every
  /// player said about how they look at it goes with it: it was about a song
  /// that is no longer played.
  ///
  /// Unlike a set, an entry is removed rather than kept as a headstone. A client
  /// that is holding a copy learns it is gone from the set it is in, which it
  /// reads whole.
  ///
  /// Only the owner of a set can take an entry out of it. An entry that is not
  /// there, is not in the set that was named, or is in a set the caller cannot
  /// read, are all answered the same way.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i19.DeleteSetEntryResponse, _i12.Response>>
  deleteSetEntry({
    required _i9.String setId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _deleteSetEntry(
    setId: setId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Say how you look at one entry of a set.
  /// Stores the caller's own view of this entry, replacing whatever they had
  /// said before, and returns it as it now reads.
  ///
  /// Anyone who can read the set can write their own view of its entries: it
  /// says nothing about the set and changes nothing anybody else sees, so it
  /// asks no more of a player than reading the set does. Being the owner is
  /// neither needed nor enough to write somebody else's — there is no way to
  /// write a view that is not your own.
  ///
  /// A set the caller cannot read, and an entry that is not in the set named, are
  /// answered the same way as one that is not there at all.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [setId] The id the set is stored under.
  /// [entryId] The entry of the set, as it was given back by a read of the set.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i9.Future<_i10.TonikResult<_i20.PutSetEntryViewResponse, _i12.Response>>
  putSetEntryView({
    required _i21.WriteEntryView body,
    required _i9.String setId,
    required _i9.String entryId,
    _i9.String? correlationId,
    _i10.TonikCancellation? cancellation,
  }) async => _putSetEntryView(
    body: body,
    setId: setId,
    entryId: entryId,
    correlationId: correlationId,
    cancellation: cancellation,
  );
}

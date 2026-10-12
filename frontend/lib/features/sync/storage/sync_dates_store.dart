import 'package:score/json_map_extensions.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/record_store.dart';

/// Where each kind of thing's next sync starts: one [SyncDate] for the scores,
/// and one for anything else that is synced by a change window.
///
/// Kept apart from what was synced, because only a sync may move it. A score
/// stored on its own — opened by a link, or read back after an upload — can be
/// newer than everything the last sync saw, and a window started after it
/// would skip whatever else changed in between.
class SyncDatesStore({
  required super.client,
}) extends SembastStore<SyncDate> {
  this
    : super(
        storeName: 'sync_dates',
        fromJson: SyncDate.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.what,
        idFieldKey: 'what',
      );

  /// When [what] was last synced, or [beginningOfTime] when it never was.
  Future<DateTime> lastSyncedAt(String what) async =>
      (await get(what))?.lastSyncedAt ?? beginningOfTime;

  Future<void> keepLastSyncedAt(String what, DateTime at) =>
      put(SyncDate(what: what, lastSyncedAt: at));

  Future<void> forgetLastSyncedAt(String what) => remove(what);
}

class const SyncDate({
  required final String what,

  /// The newest change the last sync was told about, on the server's clock.
  required final DateTime lastSyncedAt,
}) {
  factory SyncDate.fromJson(Map json) {
    return SyncDate(
      what: '${json['what']}',
      lastSyncedAt:
          json.get('last_synced_at', parser: DateTime.tryParse) ??
          beginningOfTime,
    );
  }

  Map<String, Object?> toJson() => {
    'what': what,
    'last_synced_at': lastSyncedAt.toUtc().toIso8601String(),
  };
}

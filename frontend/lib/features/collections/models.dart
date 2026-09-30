/// A collection is a group of scores that belong together without being played
/// in any particular order: the pieces a book holds, the repertoire a band can
/// be asked for.
///
/// It is the other half of what a set is. A set is a gig, where the same song
/// may come round twice and the order is what is played; here order says
/// nothing, and a score is in it or it is not. Everything else is the same,
/// because it is the same music — and it is kept the same way for the same
/// reason: a collection is looked at and added to on the device it is played
/// from, which is where there is no network, so an edit is stored here first
/// and sent afterwards.
library;

// How far a score may be read from where it is written is the viewer's to say,
// so it is said there and not here, and the same goes for the set's rules about
// keys and addresses: a collection reads the same music the same way, so it
// takes them as they are rather than keeping a second copy that could drift.
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/sets/models.dart'
    show
        EntryView,
        PendingChange,
        PendingEntry,
        SyncedEntry,
        SyncedRecord,
        scoreIdOf,
        transpositionOf;
import 'package:score/json.dart';

export 'package:score/features/sets/models.dart'
    show
        EntryView,
        PendingChange,
        PendingEntry,
        addressesIn,
        addressesOf,
        keptOf,
        maxZoom,
        mergedEntries,
        minZoom,
        owing,
        pullOverlap,
        scoreIdOf,
        transpositionOf,
        withoutOwed,
        zoomOf;

/// A collection as this app keeps it: what the API says a collection is, plus
/// what only this device knows — when it last heard from the server about it,
/// and what it still owes the server.
class Collection implements SyncedRecord<Collection, CollectionEntry> {
  const Collection({
    required this.id,
    this.title = '',
    this.description = '',
    this.entries = const [],
    this.sharedWith = const [],
    this.isOwner = true,
    required this.lastChangedAt,
    this.deletedAt,
    this.lastSyncedAt,
    this.pendingChange,
    this.pendingViews = const [],
    this.pendingEntries = const [],
  });

  /// A collection the way the API hands it over, as one this app keeps: the
  /// moments as dates rather than as the strings they arrive as, and nothing
  /// owed.
  factory Collection.fromApi(
    Map<String, dynamic> json,
    DateTime syncedAt,
  ) =>
      Collection(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        entries: [
          for (final entry in (json['entries'] as List? ?? []))
            CollectionEntry.fromApi((entry as Map).cast<String, dynamic>()),
        ],
        sharedWith: [
          for (final address in (json['shared_with'] as List? ?? [])) '$address',
        ],
        isOwner: json['is_owner'] == true,
        lastChangedAt:
            dateOf(json['last_changed_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: dateOf(json['deleted_at']),
        lastSyncedAt: syncedAt,
      );

  /// A collection as this device stored it — which is also how the app that was
  /// there before this one stored it, so what it left behind in a browser is
  /// read by this and nothing else.
  factory Collection.fromJson(
    Map<String, Object?> json,
  ) =>
      Collection(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        entries: [
          for (final entry in (json['entries'] as List? ?? []))
            CollectionEntry.fromJson((entry as Map).cast<String, Object?>()),
        ],
        sharedWith: [
          for (final address in (json['shared_with'] as List? ?? [])) '$address',
        ],
        isOwner: json['is_owner'] != false,
        lastChangedAt: dateOf(json['last_changed_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: dateOf(json['deleted_at']),
        lastSyncedAt: dateOf(json['last_synced_at']),
        pendingChange: json['pending_change'] as String?,
        pendingViews: [
          for (final id in (json['pending_views'] as List? ?? [])) '$id',
        ],
        pendingEntries: [
          for (final owed in (json['pending_entries'] as List? ?? []))
            PendingEntry.fromJson((owed as Map).cast<String, Object?>()),
        ],
      );

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;

  /// The pieces in it.
  ///
  /// They are kept in whatever order they arrived in — by title from the
  /// server, and at the end for anything added here — and that is not an order
  /// the collection has, because it has none. What a piece is called is in its
  /// score rather than in the entry, so a list is sorted where the titles are,
  /// which is [entriesByTitle].
  @override
  final List<CollectionEntry> entries;

  /// The addresses it is readable by; only ever filled in for the owner.
  @override
  final List<String> sharedWith;

  /// Whether it is this user's to change.
  @override
  final bool isOwner;

  /// When it was last written, here or there.
  @override
  final DateTime lastChangedAt;

  /// When it was deleted, or null while it exists.
  @override
  final DateTime? deletedAt;

  /// When the server last said what is above.
  @override
  final DateTime? lastSyncedAt;

  /// One of [PendingChange], or null when there is nothing owed.
  @override
  final String? pendingChange;

  /// The entries whose view this user has written here and the server has not
  /// heard about yet.
  ///
  /// A view is written by whoever it belongs to rather than by the owner, so it
  /// is owed separately: a player who cannot add a piece to the book still has
  /// their own reading of one that is in it to send.
  @override
  final List<String> pendingViews;

  /// What has been done to the collection here and not sent yet, in the order
  /// it was done.
  ///
  /// Entries are written one at a time, so what is owed is one piece at a time
  /// rather than the whole book.
  @override
  final List<PendingEntry> pendingEntries;

  @override
  bool get owesAnything =>
      pendingChange != null ||
      pendingEntries.isNotEmpty ||
      pendingViews.isNotEmpty;

  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled collection' : title;

  /// Whether the given score is one of the pieces in it.
  bool holds(String scoreId) =>
      entries.any((entry) => entry.scoreId == scoreId);

  @override
  Collection copyWith({
    String? title,
    String? description,
    List<CollectionEntry>? entries,
    List<String>? sharedWith,
    bool? isOwner,
    DateTime? lastChangedAt,
    DateTime? deletedAt,
    DateTime? lastSyncedAt,
    String? pendingChange,
    List<String>? pendingViews,
    List<PendingEntry>? pendingEntries,
    bool clearPendingChange = false,
    bool clearDeletedAt = false,
  }) =>
      Collection(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        entries: entries ?? this.entries,
        sharedWith: sharedWith ?? this.sharedWith,
        isOwner: isOwner ?? this.isOwner,
        lastChangedAt: lastChangedAt ?? this.lastChangedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pendingChange:
            clearPendingChange ? null : (pendingChange ?? this.pendingChange),
        pendingViews: pendingViews ?? this.pendingViews,
        pendingEntries: pendingEntries ?? this.pendingEntries,
      );

  @override
  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'entries': [for (final entry in entries) entry.toJson()],
        'shared_with': sharedWith,
        'is_owner': isOwner,
        // In UTC, for the reason a set's are (see ScoreSet.toJson): a local
        // moment is read back in whatever zone the device is in by then.
        'last_changed_at': lastChangedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
        'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
        'pending_change': pendingChange,
        'pending_views': pendingViews,
        'pending_entries': [for (final owed in pendingEntries) owed.toJson()],
      };
}

/// One piece in a collection.
///
/// Everything here but the view is what the group does with the piece, which is
/// the same for everyone the collection is shared with and the owner's to say.
///
/// There is no position. Where a piece comes in a collection is not a thing a
/// collection has an answer to.
class CollectionEntry implements SyncedEntry<CollectionEntry> {
  const CollectionEntry({
    required this.id,
    this.scoreId,
    this.description = '',
    this.transposition = 0,
    this.view = const CollectionEntryView(),
    this.synced = false,
  });

  factory CollectionEntry.fromApi(
    Map<String, dynamic> json,
  ) =>
      CollectionEntry(
        id: '${json['id']}',
        scoreId: scoreIdOf(json['score_id']),
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: CollectionEntryView.fromJson(json['view']),
        // Everything the API hands over is on the server by definition.
        synced: true,
      );

  factory CollectionEntry.fromJson(
    Map<String, Object?> json,
  ) =>
      CollectionEntry(
        id: '${json['id']}',
        scoreId: scoreIdOf(json['score_id']),
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: CollectionEntryView.fromJson(json['view']),
        synced: json['synced'] == true,
      );

  /// What this entry is called, here and on the server.
  ///
  /// An entry added here is named here, and the server keeps the name, which is
  /// what lets a player put a piece in and say how they read it before either
  /// has been sent anywhere.
  @override
  final String id;

  /// The piece, and null for one that is in the collection but not in here — a
  /// page of a book nobody has scanned.
  ///
  /// A score is in a collection at most once; the pieces that have none are
  /// outside that rule, since they are told apart by what is written next to
  /// them.
  final String? scoreId;

  /// Whatever is worth remembering about this one — and, for a piece with no
  /// score, the only name it has.
  final String description;

  /// How far the group plays this one from where it is written, in semitones,
  /// negative for down.
  final int transposition;

  /// How this user looks at it, which is theirs alone.
  @override
  final CollectionEntryView view;

  /// Whether the server has this entry. An entry that was added here and never
  /// sent is nothing to tell the server about when it is taken out again: there
  /// is no row there to remove.
  @override
  final bool synced;

  /// Whether this is a piece that has yet to be scanned: in the book, and not
  /// in here.
  bool get isOnPaper => scoreId == null;

  /// How far the score is read from where it is written: the key the group
  /// plays it in, plus how far this player reads it from there.
  ///
  /// The two are added rather than one replacing the other, and the sum is held
  /// to the range the player offers — an octave either way is as far as the
  /// control goes, whatever the two of them add up to.
  int get readAt => (transposition + view.transposition)
      .clamp(minTransposition, maxTransposition);

  /// Which piece it is, as somebody looking down the list reads it: the title
  /// of its score, and what is written next to it when there is no score to
  /// take a title from.
  ///
  /// The title is in the score rather than in the entry, so it is asked for
  /// rather than kept: [titleOf] is handed the score's id and says what that
  /// score is called on this device, or null when it is not on it yet.
  String nameWith(String? Function(String scoreId) titleOf) {
    final scoreId = this.scoreId;
    if (scoreId == null) {
      final written = description.trim();
      return written.isEmpty ? 'A piece, not scanned yet' : written;
    }
    return titleOf(scoreId) ?? 'Not on this device yet';
  }

  /// A copy with some of it said differently.
  ///
  /// Which piece it is is asked for by name rather than by whether it is filled
  /// in: `null` is a piece that is in the collection but not in here, and
  /// reading that as nothing said would put the score back on an entry somebody
  /// has just said has none. So taking the score away is [clearScoreId].
  @override
  CollectionEntry copyWith({
    String? scoreId,
    String? description,
    int? transposition,
    CollectionEntryView? view,
    bool? synced,
    bool clearScoreId = false,
  }) =>
      CollectionEntry(
        id: id,
        scoreId: clearScoreId ? null : (scoreId ?? this.scoreId),
        description: description ?? this.description,
        transposition: transposition ?? this.transposition,
        view: view ?? this.view,
        synced: synced ?? this.synced,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        // Null rather than left out, and never written as text: an entry read
        // back with a score called `null` would be sent to the server as a
        // score that does not exist, and would stop being a piece on paper.
        'score_id': scoreId,
        'description': description,
        'transposition': transposition,
        'view': view.toJson(),
        'synced': synced,
      };
}

/// How one player looks at one entry of a collection: the same thing, read the
/// same way, as how they look at one entry of a set — the key on top of the
/// group's, the parts on screen, and how big they draw it.
typedef CollectionEntryView = EntryView;


/// The entries of a collection by title, which is how a collection is read: it
/// has no order of its own, and what a piece is called is in its score rather
/// than in the entry. A piece with no score is filed under what is written next
/// to it, which is the only name it has.
///
/// It is the one order a collection is shown in — its page and the way through
/// it from a score both use it — so that "3 of 21" on the score means the third
/// one down the page somebody was just looking at.
List<CollectionEntry> entriesByTitle(
  Iterable<CollectionEntry> entries,
  String? Function(String scoreId) titleOf,
) {
  String keyOf(CollectionEntry entry) =>
      entry.nameWith(titleOf).toLowerCase();

  return [...entries]..sort((a, b) {
      final byName = keyOf(a).compareTo(keyOf(b));
      // Two pieces that are called the same are still two pieces, and which of
      // them comes first must not change every time the list is drawn.
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
}

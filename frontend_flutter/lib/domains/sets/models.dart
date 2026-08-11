/// A set is a playlist for a gig: the scores that are played, in playing order,
/// each in the key it is played in.
///
/// A set is edited on the device it is played from, and a gig is exactly where
/// there is no network, so an edit is stored here first and sent afterwards.
/// That makes what is stored the truth for as long as it takes a write to reach
/// the API: what is here is what the player sees, whether or not the server has
/// heard of it yet.
library;

// How far a score may be read from where it is written is the viewer's to say,
// so it is said there and not here: a set that stored a key the score could not
// be shown in would be a set nobody could play.
import '../../notation/view/score_view.dart';

/// What a set is waiting to have done to it on the server.
class PendingChange {
  /// It was written here and the write has not reached the server yet.
  static const write = 'write';

  /// It was deleted here and the delete has not reached the server yet.
  static const delete = 'delete';
}

/// A set as this app keeps it: what the API says a set is, plus what only this
/// device knows — when it last heard from the server about it, and what it
/// still owes the server.
///
/// It is called a `ScoreSet` rather than a `Set` because the other one is
/// taken.
class ScoreSet {
  const ScoreSet({
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

  final String id;
  final String title;
  final String description;

  /// In playing order.
  final List<SetEntry> entries;

  /// The addresses it is readable by; only ever filled in for the owner.
  final List<String> sharedWith;

  /// Whether it is this user's to change.
  final bool isOwner;

  /// When it was last written, here or there.
  final DateTime lastChangedAt;

  /// When it was deleted, or null while it exists.
  final DateTime? deletedAt;

  /// When the server last said what is above.
  final DateTime? lastSyncedAt;

  /// One of [PendingChange], or null when there is nothing owed.
  final String? pendingChange;

  /// The entries whose view this user has written here and the server has not
  /// heard about yet.
  ///
  /// A view is written by whoever it belongs to rather than by the owner of the
  /// set, so it is owed separately from the set: a player who cannot change a
  /// note of the running order still has their own reading of it to send.
  final List<String> pendingViews;

  /// What has been done to the running order here and not sent yet, in the
  /// order it was done.
  ///
  /// Entries are written one at a time, so what is owed is one song at a time
  /// rather than the whole list: a client that added a song at a gig sends that
  /// song, and nothing it says can undo what somebody else did to the rest of
  /// the set in the meantime.
  final List<PendingEntry> pendingEntries;

  bool get owesAnything =>
      pendingChange != null ||
      pendingEntries.isNotEmpty ||
      pendingViews.isNotEmpty;

  String get displayTitle => title.trim().isEmpty ? 'Untitled set' : title;

  ScoreSet copyWith({
    String? title,
    String? description,
    List<SetEntry>? entries,
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
      ScoreSet(
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

  /// A set the way the API hands it over, as one this app keeps: the moments as
  /// dates rather than as the strings they arrive as, and nothing owed.
  factory ScoreSet.fromApi(Map<String, dynamic> json, DateTime syncedAt) =>
      ScoreSet(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        entries: [
          for (final entry in (json['entries'] as List? ?? []))
            SetEntry.fromApi((entry as Map).cast<String, dynamic>()),
        ],
        sharedWith: [
          for (final address in (json['shared_with'] as List? ?? [])) '$address',
        ],
        isOwner: json['is_owner'] == true,
        lastChangedAt:
            _date(json['last_changed_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: _date(json['deleted_at']),
        lastSyncedAt: syncedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'entries': [for (final entry in entries) entry.toJson()],
        'shared_with': sharedWith,
        'is_owner': isOwner,
        'last_changed_at': lastChangedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'last_synced_at': lastSyncedAt?.toIso8601String(),
        'pending_change': pendingChange,
        'pending_views': pendingViews,
        'pending_entries': [for (final owed in pendingEntries) owed.toJson()],
      };

  factory ScoreSet.fromJson(Map<String, Object?> json) => ScoreSet(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        entries: [
          for (final entry in (json['entries'] as List? ?? []))
            SetEntry.fromJson((entry as Map).cast<String, Object?>()),
        ],
        sharedWith: [
          for (final address in (json['shared_with'] as List? ?? [])) '$address',
        ],
        isOwner: json['is_owner'] != false,
        lastChangedAt: _date(json['last_changed_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: _date(json['deleted_at']),
        lastSyncedAt: _date(json['last_synced_at']),
        pendingChange: json['pending_change'] as String?,
        pendingViews: [
          for (final id in (json['pending_views'] as List? ?? [])) '$id',
        ],
        pendingEntries: [
          for (final owed in (json['pending_entries'] as List? ?? []))
            PendingEntry.fromJson((owed as Map).cast<String, Object?>()),
        ],
      );
}

/// One score in a set.
///
/// Everything here but the view is what the band does, which is the same for
/// everyone the set is shared with and the owner's to say.
class SetEntry {
  const SetEntry({
    required this.id,
    required this.scoreId,
    this.description = '',
    this.transposition = 0,
    this.view = const EntryView(),
    this.synced = false,
  });

  /// What this entry is called, here and on the server.
  ///
  /// An entry keeps its id across a write of the set, which is what lets a view
  /// of it go on pointing at the same thing; an entry added here is named here,
  /// and the server keeps the name.
  final String id;

  final String scoreId;
  final String description;

  /// How far the band plays this one from where it is written, in semitones,
  /// negative for down.
  final int transposition;

  /// How this user looks at it, which is theirs alone.
  final EntryView view;

  /// Whether the server has this entry. An entry that was added here and never
  /// sent is nothing to tell the server about when it is taken out again: there
  /// is no row there to remove.
  final bool synced;

  /// How far the score is read from where it is written: the key the band plays
  /// it in, plus how far this player reads it from there.
  ///
  /// The two are added rather than one replacing the other, and the sum is held
  /// to the range the player offers — an octave either way is as far as the
  /// control goes, whatever the two of them add up to.
  int get readAt =>
      (transposition + view.transposition).clamp(minTransposition, maxTransposition);

  SetEntry copyWith({
    String? scoreId,
    String? description,
    int? transposition,
    EntryView? view,
    bool? synced,
  }) =>
      SetEntry(
        id: id,
        scoreId: scoreId ?? this.scoreId,
        description: description ?? this.description,
        transposition: transposition ?? this.transposition,
        view: view ?? this.view,
        synced: synced ?? this.synced,
      );

  factory SetEntry.fromApi(Map<String, dynamic> json) => SetEntry(
        id: '${json['id']}',
        scoreId: '${json['score_id']}',
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: EntryView.fromJson(json['view']),
        // Everything the API hands over is on the server by definition.
        synced: true,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'score_id': scoreId,
        'description': description,
        'transposition': transposition,
        'view': view.toJson(),
        'synced': synced,
      };

  factory SetEntry.fromJson(Map<String, Object?> json) => SetEntry(
        id: '${json['id']}',
        scoreId: '${json['score_id']}',
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: EntryView.fromJson(json['view']),
        synced: json['synced'] == true,
      );
}

/// How one player looks at one entry: on top of the key the band plays it in,
/// and which parts they have on screen.
///
/// The saxophone player reading their part a sixth up changes nothing for the
/// pianist, and the pianist wanting the piano staff alone changes nothing for
/// the singer.
class EntryView {
  const EntryView({this.transposition = 0, this.hiddenParts = const []});

  /// Semitones on top of the entry's own.
  final int transposition;

  /// By MusicXML part id.
  final List<String> hiddenParts;

  static EntryView fromJson(Object? json) {
    if (json is! Map) return const EntryView();
    return EntryView(
      transposition: transpositionOf(json['transposition']),
      hiddenParts: [
        for (final part in (json['hidden_parts'] as List? ?? [])) '$part',
      ],
    );
  }

  Map<String, Object?> toJson() =>
      {'transposition': transposition, 'hidden_parts': hiddenParts};
}

/// One thing owed to the server about one entry.
class PendingEntry {
  const PendingEntry(this.id, this.action);

  final String id;

  /// One of [PendingChange].
  final String action;

  Map<String, Object?> toJson() => {'id': id, 'action': action};

  factory PendingEntry.fromJson(Map<String, Object?> json) =>
      PendingEntry('${json['id']}', '${json['action']}');
}

/// A transposition the API will take: a whole number of semitones, within the
/// octave either way that the player offers.
int transpositionOf(Object? semitones) {
  final asNumber = semitones is num
      ? semitones
      : num.tryParse('${semitones ?? ''}');
  if (asNumber == null || !asNumber.isFinite) {
    return 0;
  }
  return asNumber.round().clamp(minTransposition, maxTransposition);
}

/// The addresses a set is shared with, as the API compares them: in lower case,
/// each of them once.
///
/// Whether they are addresses at all is the server's to say — it refuses
/// anything that is not one rather than tidying it up, and a share that was
/// going to go nowhere is better said so than quietly dropped here.
List<String> addressesOf(Iterable<String> addresses) {
  final seen = <String>[];
  for (final address in addresses) {
    final trimmed = address.trim().toLowerCase();
    if (trimmed.isNotEmpty && !seen.contains(trimmed)) {
      seen.add(trimmed);
    }
  }
  return seen;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

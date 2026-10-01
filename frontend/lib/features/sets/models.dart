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
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/json.dart';

/// How far back each sync asks for changes before the end of the last one.
///
/// Where the last one ended is read off the server's own clock (see
/// [watermarkOf]), but a change is stamped when it is made and may only be
/// visible a moment later, after a newer one was already answered with. Asking
/// again for a stretch that was already asked for costs a few sets and
/// collections read twice; not asking loses them.
const Duration pullOverlap = Duration(minutes: 15);

/// Where a pull that was answered with [answer] has read up to: the newest
/// change in it, as the server stamped it.
///
/// Not this device's clock. The server filters the window on its own, and a
/// device whose clock runs ahead — by more than [pullOverlap], after a flight
/// or on a tablet whose clock was never set — would record a window that ends
/// after changes the server has not made yet, and the next pull would start
/// past them. [asked] is what it falls back on for an answer that says when
/// nothing changed.
DateTime watermarkOf(List<Map<String, dynamic>> answer, DateTime asked) {
  DateTime? newest;
  for (final json in answer) {
    for (final at in [
      dateOf(json['last_changed_at']),
      dateOf(json['deleted_at']),
    ]) {
      if (at != null && (newest == null || at.isAfter(newest))) newest = at;
    }
  }
  return newest ?? asked;
}

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
class ScoreSet implements SyncedRecord<ScoreSet, SetEntry> {
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

  /// A set the way the API hands it over, as one this app keeps: the moments as
  /// dates rather than as the strings they arrive as, and nothing owed.
  factory ScoreSet.fromApi(
    Map<String, dynamic> json,
    DateTime syncedAt,
  ) =>
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
            dateOf(json['last_changed_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: dateOf(json['deleted_at']),
        lastSyncedAt: syncedAt,
      );

  factory ScoreSet.fromJson(
    Map<String, Object?> json,
  ) => ScoreSet(
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

  /// In playing order.
  @override
  final List<SetEntry> entries;

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
  /// A view is written by whoever it belongs to rather than by the owner of the
  /// set, so it is owed separately from the set: a player who cannot change a
  /// note of the running order still has their own reading of it to send.
  @override
  final List<String> pendingViews;

  /// What has been done to the running order here and not sent yet, in the
  /// order it was done.
  ///
  /// Entries are written one at a time, so what is owed is one song at a time
  /// rather than the whole list: a client that added a song at a gig sends that
  /// song, and nothing it says can undo what somebody else did to the rest of
  /// the set in the meantime.
  @override
  final List<PendingEntry> pendingEntries;

  @override
  bool get owesAnything =>
      pendingChange != null ||
      pendingEntries.isNotEmpty ||
      pendingViews.isNotEmpty;

  String get displayTitle => title.trim().isEmpty ? 'Untitled set' : title;

  @override
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

  @override
  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'entries': [for (final entry in entries) entry.toJson()],
        'shared_with': sharedWith,
        'is_owner': isOwner,
        // In UTC: a moment written out as this device's local time carries no
        // offset, and is read back as local time in whatever zone the device
        // is in by then — hours off after a flight, which moves the sync
        // watermark past changes it never asked for.
        'last_changed_at': lastChangedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
        'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
        'pending_change': pendingChange,
        'pending_views': pendingViews,
        'pending_entries': [for (final owed in pendingEntries) owed.toJson()],
      };
}

/// The score an entry plays, and null for one that has none — a song played
/// from paper, a page of a book nobody has scanned.
///
/// A blank is nothing rather than a score with no name: a form hands over what
/// was typed into it, and what nobody typed a score into is an entry with no
/// score. The text `null` is nothing too — it is what a null turns into when it
/// is written out as text, which this app once did, and read back as an id it
/// would be sent to the server as a score that does not exist.
///
/// It is the one rule for a set's entries and a collection's: they read the
/// same music, and two copies of the rule had already come to disagree.
String? scoreIdOf(Object? value) {
  if (value == null) return null;
  final id = '$value'.trim();
  return id.isEmpty || id == 'null' ? null : id;
}

/// One score in a set.
///
/// Everything here but the view is what the band does, which is the same for
/// everyone the set is shared with and the owner's to say.
class SetEntry implements SyncedEntry<SetEntry> {
  const SetEntry({
    required this.id,
    required this.scoreId,
    this.description = '',
    this.transposition = 0,
    this.view = const EntryView(),
    this.synced = false,
  });

  factory SetEntry.fromApi(
    Map<String, dynamic> json,
  ) => SetEntry(
        id: '${json['id']}',
        scoreId: scoreIdOf(json['score_id']),
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: EntryView.fromJson(json['view']),
        // Everything the API hands over is on the server by definition.
        synced: true,
      );

  factory SetEntry.fromJson(
    Map<String, Object?> json,
  ) => SetEntry(
        id: '${json['id']}',
        scoreId: scoreIdOf(json['score_id']),
        description: '${json['description'] ?? ''}',
        transposition: transpositionOf(json['transposition']),
        view: EntryView.fromJson(json['view']),
        synced: json['synced'] == true,
      );

  /// What this entry is called, here and on the server.
  ///
  /// An entry keeps its id across a write of the set, which is what lets a view
  /// of it go on pointing at the same thing; an entry added here is named here,
  /// and the server keeps the name.
  @override
  final String id;

  /// The score that is played, or null for a song that has none — one the
  /// band still plays from paper. It is still in the running order, in its
  /// place, with its description.
  final String? scoreId;
  final String description;

  /// How far the band plays this one from where it is written, in semitones,
  /// negative for down.
  final int transposition;

  /// How this user looks at it, which is theirs alone.
  @override
  final EntryView view;

  /// Whether the server has this entry. An entry that was added here and never
  /// sent is nothing to tell the server about when it is taken out again: there
  /// is no row there to remove.
  @override
  final bool synced;

  /// How far the score is read from where it is written: the key the band plays
  /// it in, plus how far this player reads it from there.
  ///
  /// The two are added rather than one replacing the other, and the sum is held
  /// to the range the player offers — an octave either way is as far as the
  /// control goes, whatever the two of them add up to.
  int get readAt =>
      (transposition + view.transposition).clamp(minTransposition, maxTransposition);

  @override
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

  Map<String, Object?> toJson() => {
        'id': id,
        'score_id': scoreId,
        'description': description,
        'transposition': transposition,
        'view': view.toJson(),
        'synced': synced,
      };
}

/// How one player looks at one entry: on top of the key the band plays it in,
/// which parts they have on screen, and how big they draw it.
///
/// The saxophone player reading their part a sixth up changes nothing for the
/// pianist, and the pianist wanting the piano staff alone changes nothing for
/// the singer.
class EntryView {
  const EntryView({
    this.transposition = 0,
    this.hiddenParts = const [],
    this.zoom = 1,
  });

  factory EntryView.fromJson(
    Object? json,
  ) {
    if (json is! Map) return const EntryView();
    return EntryView(
      transposition: transpositionOf(json['transposition']),
      hiddenParts: [
        for (final part in (json['hidden_parts'] as List? ?? [])) '$part',
      ],
      zoom: zoomOf(json['zoom']),
    );
  }

  /// Semitones on top of the entry's own.
  final int transposition;

  /// By MusicXML part id.
  final List<String> hiddenParts;

  /// How big this player draws it, where 1 is the size it is written at.
  ///
  /// It is part of the view the server keeps, and a view is written whole: one
  /// sent without it is stored as the size the score is written at, over
  /// whatever size the player had.
  final double zoom;

  Map<String, Object?> toJson() => {
        'transposition': transposition,
        'hidden_parts': hiddenParts,
        'zoom': zoom,
      };
}

/// The smallest a player may draw a score, where 1 is the size it is written
/// at. It is the API's bound, and a view outside it is one the API refuses.
const double minZoom = 0.5;

/// The biggest a player may draw a score, for the same reason.
const double maxZoom = 4;

/// A size the API will take, and the size a score is written at for anything
/// that is not a size at all.
double zoomOf(Object? value) {
  final asNumber = value is num ? value : num.tryParse('${value ?? ''}');
  if (asNumber == null || !asNumber.isFinite) {
    return 1;
  }
  return asNumber.toDouble().clamp(minZoom, maxZoom);
}

/// What a set and a collection have in common, which is everything the engine
/// that keeps them in step with the server reads and writes (see
/// `SyncEngine`).
///
/// It is all of what they are but their entries. The two are kept the same
/// way, for the same reason, and the one thing that tells them apart — that a
/// set has a running order and a collection holds a piece once — is not in
/// here but in what is written about their entries.
abstract interface class SyncedRecord<R, E> {
  String get id;
  String get title;
  String get description;
  List<E> get entries;
  List<String> get sharedWith;
  bool get isOwner;
  DateTime get lastChangedAt;
  DateTime? get deletedAt;
  DateTime? get lastSyncedAt;
  String? get pendingChange;
  List<String> get pendingViews;
  List<PendingEntry> get pendingEntries;
  bool get owesAnything;

  R copyWith({
    String? title,
    String? description,
    List<E>? entries,
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
  });

  Map<String, Object?> toJson();
}

/// What an entry of a set and one of a collection have in common, as far as
/// keeping them in step with the server goes: what it is called, how this
/// user looks at it, and whether the server has it.
abstract interface class SyncedEntry<E> {
  String get id;
  EntryView get view;
  bool get synced;

  E copyWith({EntryView? view, bool? synced});
}

/// One thing owed to the server about one entry.
class PendingEntry {
  const PendingEntry(
    this.id,
    this.action,
  );

  factory PendingEntry.fromJson(
    Map<String, Object?> json,
  ) =>
      PendingEntry('${json['id']}', '${json['action']}');

  final String id;

  /// One of [PendingChange].
  final String action;

  Map<String, Object?> toJson() => {'id': id, 'action': action};
}

/// What is owed about the entries of a set or a collection, with one entry now
/// owing [action].
///
/// An entry is owed once however often it is written: what goes out is the
/// entry as it now reads, not every edit that was made to it. The last thing
/// said about it is what is said, so a write that follows a delete replaces it.
List<PendingEntry> owing(
  List<PendingEntry> owed,
  String entryId,
  String action,
) =>
    [...withoutOwed(owed, entryId), PendingEntry(entryId, action)];

/// What is owed about the entries of a set or a collection, with nothing owed
/// about [entryId] any more.
List<PendingEntry> withoutOwed(List<PendingEntry> owed, String entryId) =>
    owed.where((entry) => entry.id != entryId).toList();

/// The entry ids of [owed] that are still among [ids]. What was owed about an
/// entry that is no longer there is about nothing any more — a view of a song
/// that is no longer played.
List<String> keptOf(List<String> owed, Iterable<String> ids) {
  if (owed.isEmpty) {
    return const [];
  }
  final there = ids.toSet();
  return owed.where(there.contains).toList();
}

/// The entries the server says a set or a collection has, with the ones that
/// are owed to it as this device has them.
///
/// Only those are taken from here. The rest is the server's, and that includes
/// whatever another device put in or took out: keeping this device's list
/// whole while one entry is owed would lose that for good, since the next sync
/// only asks about what changed after this one. An entry that is owed goes back
/// in at the place it has here — which in a set is where it is sent to as
/// well, and in a collection is as close as a list that has changed underneath
/// it can come to where it was put.
List<E> mergedEntries<E>(
  List<E> incoming,
  List<E> existing,
  List<PendingEntry> owed,
  String Function(E entry) idOf,
) {
  if (owed.isEmpty) {
    return incoming;
  }
  final owedIds = {for (final entry in owed) entry.id};
  final merged = [
    for (final entry in incoming)
      if (!owedIds.contains(idOf(entry))) entry,
  ];
  for (final (index, entry) in existing.indexed) {
    if (owedIds.contains(idOf(entry))) {
      merged.insert(index.clamp(0, merged.length), entry);
    }
  }
  return merged;
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

/// The addresses typed into a field: one per line, or separated by commas or
/// semicolons the way an address book pastes them. Kept as [addressesOf] keeps
/// them.
List<String> addressesIn(String text) =>
    addressesOf(text.split(RegExp(r'[\n,;]')));

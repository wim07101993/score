import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sync/models.dart';
import 'package:score/json_map_extensions.dart';
import 'package:score/storage/clients.dart';

class const ScoreSet({
  @override required final String id,
  @override required final DateTime lastChangedAt,
  required final String title,
  required final String description,
  required final List<SetEntry> entries,
  required final List<String> sharedWith,
  required final bool isOwner,
  required final DateTime? deletedAt,
}) implements SyncableModel {
  factory ScoreSet.fromJson(Map json) {
    return ScoreSet(
      id: json.get(idFieldKey) ?? (throw Exception('no id provided for set')),
      title: json.get<String>('title') ?? '',
      description: json.get<String>('description') ?? '',
      entries: json
          .getList<Map>('entries')
          .map(SetEntry.fromJson)
          .toList(growable: false),
      sharedWith: json.getList('shared_with'),
      isOwner: json.get<bool>('is_owner') ?? true,
      lastChangedAt:
          json.get(lastChangedAtFieldKey, parser: DateTime.tryParse) ??
          beginningOfTime,
      deletedAt: json.get('deleted_at', parser: DateTime.tryParse),
    );
  }

  static const String lastChangedAtFieldKey = 'last_changed_at';
  static const String idFieldKey = 'id';

  String get displayTitle => title.trim().isEmpty ? 'Untitled set' : title;

  ScoreSet copyWith({
    String? title,
    String? description,
    List<SetEntry>? entries,
    List<String>? sharedWith,
    bool? isOwner,
    DateTime? lastChangedAt,
    DateTime? deletedAt,
  }) => ScoreSet(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    entries: entries ?? this.entries,
    sharedWith: sharedWith ?? this.sharedWith,
    isOwner: isOwner ?? this.isOwner,
    lastChangedAt: lastChangedAt ?? this.lastChangedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  Map<String, Object?> toJson() => {
    idFieldKey: id,
    'title': title,
    'description': description,
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    'shared_with': sharedWith,
    'is_owner': isOwner,
    lastChangedAtFieldKey: lastChangedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
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

class const SetEntry({
  required final String id,
  required final String? scoreId,
  required final String description,
  required final int transposition,
  final ScoreViewSettings view = const ScoreViewSettings.defaultView(),
}) {
  factory SetEntry.fromJson(Map json) {
    return SetEntry(
      id: '${json['id']}',
      scoreId: scoreIdOf(json['score_id']),
      description: json.get<String>('description') ?? '',
      transposition: json.get('transposition', parser: int.tryParse) ?? 0,
      view:
          json.getObject('view', ScoreViewSettings.fromJson) ??
          const ScoreViewSettings.defaultView(),
    );
  }

  int get readAt => (transposition + view.transposition).clamp(
    ScoreViewSettings.minTransposition,
    ScoreViewSettings.maxTransposition,
  );

  SetEntry copyWith({
    String? scoreId,
    String? description,
    int? transposition,
    ScoreViewSettings? view,
  }) => SetEntry(
    id: id,
    scoreId: scoreId ?? this.scoreId,
    description: description ?? this.description,
    transposition: transposition ?? this.transposition,
    view: view ?? this.view,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'score_id': scoreId,
    'description': description,
    'transposition': transposition,
    'view': view.toJson(),
  };
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

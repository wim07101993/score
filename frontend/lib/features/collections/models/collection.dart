import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/sync/models.dart';
import 'package:score/json_map_extensions.dart';
import 'package:score/storage/clients.dart';

class const Collection({
  @override required final String id,
  @override required final DateTime lastChangedAt,
  required final String title,
  required final String description,
  required final List<CollectionEntry> entries,
  required final List<String> sharedWith,
  required final bool isOwner,
  required final DateTime? deletedAt,
}) implements SyncableModel {
  factory Collection.fromJson(Map json) {
    return Collection(
      id:
          json.get(idFieldKey) ??
          (throw Exception('no id provided for collection')),
      title: json.get<String>('title') ?? '',
      description: json.get<String>('description') ?? '',
      entries: json
          .getList<Map>('entries')
          .map(CollectionEntry.fromJson)
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

  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled collection' : title;

  bool holds(String scoreId) =>
      entries.any((entry) => entry.scoreId == scoreId);

  Collection copyWith({
    String? title,
    String? description,
    List<CollectionEntry>? entries,
    List<String>? sharedWith,
    bool? isOwner,
    DateTime? lastChangedAt,
    DateTime? deletedAt,
  }) => Collection(
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

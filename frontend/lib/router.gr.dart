// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [CollectionDetailPage]
class CollectionDetailRoute extends PageRouteInfo<CollectionDetailRouteArgs> {
  CollectionDetailRoute({
    Key? key,
    required String collectionId,
    List<PageRouteInfo>? children,
  }) : super(
         CollectionDetailRoute.name,
         args: CollectionDetailRouteArgs(key: key, collectionId: collectionId),
         rawPathParams: {'collectionId': collectionId},
         initialChildren: children,
       );

  static const String name = 'CollectionDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<CollectionDetailRouteArgs>(
        orElse: () => CollectionDetailRouteArgs(
          collectionId: pathParams.getString('collectionId'),
        ),
      );
      return CollectionDetailPage(
        key: args.key,
        collectionId: args.collectionId,
      );
    },
  );
}

class CollectionDetailRouteArgs {
  const CollectionDetailRouteArgs({this.key, required this.collectionId});

  final Key? key;

  final String collectionId;

  @override
  String toString() {
    return 'CollectionDetailRouteArgs{key: $key, collectionId: $collectionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectionDetailRouteArgs) return false;
    return key == other.key && collectionId == other.collectionId;
  }

  @override
  int get hashCode => key.hashCode ^ collectionId.hashCode;
}

/// generated route for
/// [CollectionsPage]
class CollectionsRoute extends PageRouteInfo<void> {
  const CollectionsRoute({List<PageRouteInfo>? children})
    : super(CollectionsRoute.name, initialChildren: children);

  static const String name = 'CollectionsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CollectionsPage();
    },
  );
}

/// generated route for
/// [LogsPage]
class LogsRoute extends PageRouteInfo<void> {
  const LogsRoute({List<PageRouteInfo>? children})
    : super(LogsRoute.name, initialChildren: children);

  static const String name = 'LogsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LogsPage();
    },
  );
}

/// generated route for
/// [PerformScorePage]
class PerformScoreRoute extends PageRouteInfo<PerformScoreRouteArgs> {
  PerformScoreRoute({
    Key? key,
    required String scoreId,
    String? setId,
    String? collectionId,
    String? entryId,
    ScoreReadingHandover? handover,
    List<PageRouteInfo>? children,
  }) : super(
         PerformScoreRoute.name,
         args: PerformScoreRouteArgs(
           key: key,
           scoreId: scoreId,
           setId: setId,
           collectionId: collectionId,
           entryId: entryId,
           handover: handover,
         ),
         rawPathParams: {'scoreId': scoreId},
         rawQueryParams: {
           'set': setId,
           'collection': collectionId,
           'entry': entryId,
         },
         initialChildren: children,
       );

  static const String name = 'PerformScoreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<PerformScoreRouteArgs>(
        orElse: () => PerformScoreRouteArgs(
          scoreId: pathParams.getString('scoreId'),
          setId: queryParams.optString('set'),
          collectionId: queryParams.optString('collection'),
          entryId: queryParams.optString('entry'),
        ),
      );
      return PerformScorePage(
        key: args.key,
        scoreId: args.scoreId,
        setId: args.setId,
        collectionId: args.collectionId,
        entryId: args.entryId,
        handover: args.handover,
      );
    },
  );
}

class PerformScoreRouteArgs {
  const PerformScoreRouteArgs({
    this.key,
    required this.scoreId,
    this.setId,
    this.collectionId,
    this.entryId,
    this.handover,
  });

  final Key? key;

  final String scoreId;

  final String? setId;

  final String? collectionId;

  final String? entryId;

  final ScoreReadingHandover? handover;

  @override
  String toString() {
    return 'PerformScoreRouteArgs{key: $key, scoreId: $scoreId, setId: $setId, collectionId: $collectionId, entryId: $entryId, handover: $handover}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PerformScoreRouteArgs) return false;
    return key == other.key &&
        scoreId == other.scoreId &&
        setId == other.setId &&
        collectionId == other.collectionId &&
        entryId == other.entryId &&
        handover == other.handover;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      scoreId.hashCode ^
      setId.hashCode ^
      collectionId.hashCode ^
      entryId.hashCode ^
      handover.hashCode;
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [ScorePage]
class ScoreRoute extends PageRouteInfo<ScoreRouteArgs> {
  ScoreRoute({
    Key? key,
    required String scoreId,
    String? setId,
    String? collectionId,
    String? entryId,
    List<PageRouteInfo>? children,
  }) : super(
         ScoreRoute.name,
         args: ScoreRouteArgs(
           key: key,
           scoreId: scoreId,
           setId: setId,
           collectionId: collectionId,
           entryId: entryId,
         ),
         rawPathParams: {'scoreId': scoreId},
         rawQueryParams: {
           'set': setId,
           'collection': collectionId,
           'entry': entryId,
         },
         initialChildren: children,
       );

  static const String name = 'ScoreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ScoreRouteArgs>(
        orElse: () => ScoreRouteArgs(
          scoreId: pathParams.getString('scoreId'),
          setId: queryParams.optString('set'),
          collectionId: queryParams.optString('collection'),
          entryId: queryParams.optString('entry'),
        ),
      );
      return ScorePage(
        key: args.key,
        scoreId: args.scoreId,
        setId: args.setId,
        collectionId: args.collectionId,
        entryId: args.entryId,
      );
    },
  );
}

class ScoreRouteArgs {
  const ScoreRouteArgs({
    this.key,
    required this.scoreId,
    this.setId,
    this.collectionId,
    this.entryId,
  });

  final Key? key;

  final String scoreId;

  final String? setId;

  final String? collectionId;

  final String? entryId;

  @override
  String toString() {
    return 'ScoreRouteArgs{key: $key, scoreId: $scoreId, setId: $setId, collectionId: $collectionId, entryId: $entryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScoreRouteArgs) return false;
    return key == other.key &&
        scoreId == other.scoreId &&
        setId == other.setId &&
        collectionId == other.collectionId &&
        entryId == other.entryId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      scoreId.hashCode ^
      setId.hashCode ^
      collectionId.hashCode ^
      entryId.hashCode;
}

/// generated route for
/// [ScoresPage]
class ScoresRoute extends PageRouteInfo<void> {
  const ScoresRoute({List<PageRouteInfo>? children})
    : super(ScoresRoute.name, initialChildren: children);

  static const String name = 'ScoresRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScoresPage();
    },
  );
}

/// generated route for
/// [SetDetailPage]
class SetDetailRoute extends PageRouteInfo<SetDetailRouteArgs> {
  SetDetailRoute({
    Key? key,
    required String setId,
    List<PageRouteInfo>? children,
  }) : super(
         SetDetailRoute.name,
         args: SetDetailRouteArgs(key: key, setId: setId),
         rawPathParams: {'setId': setId},
         initialChildren: children,
       );

  static const String name = 'SetDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SetDetailRouteArgs>(
        orElse: () => SetDetailRouteArgs(setId: pathParams.getString('setId')),
      );
      return SetDetailPage(key: args.key, setId: args.setId);
    },
  );
}

class SetDetailRouteArgs {
  const SetDetailRouteArgs({this.key, required this.setId});

  final Key? key;

  final String setId;

  @override
  String toString() {
    return 'SetDetailRouteArgs{key: $key, setId: $setId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetDetailRouteArgs) return false;
    return key == other.key && setId == other.setId;
  }

  @override
  int get hashCode => key.hashCode ^ setId.hashCode;
}

/// generated route for
/// [SetsPage]
class SetsRoute extends PageRouteInfo<void> {
  const SetsRoute({List<PageRouteInfo>? children})
    : super(SetsRoute.name, initialChildren: children);

  static const String name = 'SetsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SetsPage();
    },
  );
}

/// generated route for
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsPage();
    },
  );
}

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
/// [CollectionEntryPage]
class CollectionEntryRoute extends PageRouteInfo<CollectionEntryRouteArgs> {
  CollectionEntryRoute({
    Key? key,
    required String collectionId,
    required String entryId,
    bool? isPerforming,
    List<PageRouteInfo>? children,
  }) : super(
         CollectionEntryRoute.name,
         args: CollectionEntryRouteArgs(
           key: key,
           collectionId: collectionId,
           entryId: entryId,
           isPerforming: isPerforming,
         ),
         rawPathParams: {'collectionId': collectionId, 'entryId': entryId},
         rawQueryParams: {'isPerforming': isPerforming},
         initialChildren: children,
       );

  static const String name = 'CollectionEntryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<CollectionEntryRouteArgs>(
        orElse: () => CollectionEntryRouteArgs(
          collectionId: pathParams.getString('collectionId'),
          entryId: pathParams.getString('entryId'),
          isPerforming: queryParams.optBool('isPerforming'),
        ),
      );
      return CollectionEntryPage(
        key: args.key,
        collectionId: args.collectionId,
        entryId: args.entryId,
        isPerforming: args.isPerforming,
      );
    },
  );
}

class CollectionEntryRouteArgs {
  const CollectionEntryRouteArgs({
    this.key,
    required this.collectionId,
    required this.entryId,
    this.isPerforming,
  });

  final Key? key;

  final String collectionId;

  final String entryId;

  final bool? isPerforming;

  @override
  String toString() {
    return 'CollectionEntryRouteArgs{key: $key, collectionId: $collectionId, entryId: $entryId, isPerforming: $isPerforming}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectionEntryRouteArgs) return false;
    return key == other.key &&
        collectionId == other.collectionId &&
        entryId == other.entryId &&
        isPerforming == other.isPerforming;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      collectionId.hashCode ^
      entryId.hashCode ^
      isPerforming.hashCode;
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
/// [NewScorePage]
class NewScoreRoute extends PageRouteInfo<void> {
  const NewScoreRoute({List<PageRouteInfo>? children})
    : super(NewScoreRoute.name, initialChildren: children);

  static const String name = 'NewScoreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NewScorePage();
    },
  );
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
/// [ScoreDetailPage]
class ScoreDetailRoute extends PageRouteInfo<ScoreDetailRouteArgs> {
  ScoreDetailRoute({
    Key? key,
    required String scoreId,
    bool? isPerforming,
    List<PageRouteInfo>? children,
  }) : super(
         ScoreDetailRoute.name,
         args: ScoreDetailRouteArgs(
           key: key,
           scoreId: scoreId,
           isPerforming: isPerforming,
         ),
         rawPathParams: {'scoreId': scoreId},
         rawQueryParams: {'isPerforming': isPerforming},
         initialChildren: children,
       );

  static const String name = 'ScoreDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ScoreDetailRouteArgs>(
        orElse: () => ScoreDetailRouteArgs(
          scoreId: pathParams.getString('scoreId'),
          isPerforming: queryParams.optBool('isPerforming'),
        ),
      );
      return ScoreDetailPage(
        key: args.key,
        scoreId: args.scoreId,
        isPerforming: args.isPerforming,
      );
    },
  );
}

class ScoreDetailRouteArgs {
  const ScoreDetailRouteArgs({
    this.key,
    required this.scoreId,
    this.isPerforming,
  });

  final Key? key;

  final String scoreId;

  final bool? isPerforming;

  @override
  String toString() {
    return 'ScoreDetailRouteArgs{key: $key, scoreId: $scoreId, isPerforming: $isPerforming}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScoreDetailRouteArgs) return false;
    return key == other.key &&
        scoreId == other.scoreId &&
        isPerforming == other.isPerforming;
  }

  @override
  int get hashCode => key.hashCode ^ scoreId.hashCode ^ isPerforming.hashCode;
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
/// [SetEntryPage]
class SetEntryRoute extends PageRouteInfo<SetEntryRouteArgs> {
  SetEntryRoute({
    Key? key,
    required String setId,
    required String entryId,
    bool? isPerforming,
    List<PageRouteInfo>? children,
  }) : super(
         SetEntryRoute.name,
         args: SetEntryRouteArgs(
           key: key,
           setId: setId,
           entryId: entryId,
           isPerforming: isPerforming,
         ),
         rawPathParams: {'setId': setId, 'entryId': entryId},
         rawQueryParams: {'isPerforming': isPerforming},
         initialChildren: children,
       );

  static const String name = 'SetEntryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<SetEntryRouteArgs>(
        orElse: () => SetEntryRouteArgs(
          setId: pathParams.getString('setId'),
          entryId: pathParams.getString('entryId'),
          isPerforming: queryParams.optBool('isPerforming'),
        ),
      );
      return SetEntryPage(
        key: args.key,
        setId: args.setId,
        entryId: args.entryId,
        isPerforming: args.isPerforming,
      );
    },
  );
}

class SetEntryRouteArgs {
  const SetEntryRouteArgs({
    this.key,
    required this.setId,
    required this.entryId,
    this.isPerforming,
  });

  final Key? key;

  final String setId;

  final String entryId;

  final bool? isPerforming;

  @override
  String toString() {
    return 'SetEntryRouteArgs{key: $key, setId: $setId, entryId: $entryId, isPerforming: $isPerforming}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetEntryRouteArgs) return false;
    return key == other.key &&
        setId == other.setId &&
        entryId == other.entryId &&
        isPerforming == other.isPerforming;
  }

  @override
  int get hashCode =>
      key.hashCode ^ setId.hashCode ^ entryId.hashCode ^ isPerforming.hashCode;
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

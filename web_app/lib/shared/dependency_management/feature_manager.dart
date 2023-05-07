import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/dependency_management/get_it_extensions.dart';

class FeatureManager {
  FeatureManager({
    required List<Feature> features,
    required this.getIt,
  }) : _featureStatuses = {
          for (final feature in features)
            feature.runtimeType: _FeatureStatus(feature),
        } {
    assert(
      _featureStatuses.length == features.length,
      'Each feature can only occur once in the list of features',
    );
    print(_featureStatuses);
  }

  final GetIt getIt;
  final Map<Type, _FeatureStatus> _featureStatuses;
  Logger? _logger;

  Iterable<Feature> get features =>
      _featureStatuses.values.map((status) => status.feature);

  Logger? get logger {
    return _logger ??
        (!getIt.isRegistered<Logger>()
            ? null
            : _logger = getIt.logger<FeatureManager>());
  }

  void registerTypes() {
    _registerFeatures();
    for (final feature in features) {
      _ensureFeatureTypesRegistered(feature);
    }
  }

  void _registerFeatures() {
    final features = this
        .features
        .where((feature) => !getIt.isRegistered(instance: feature));

    for (final feature in features) {
      if (!getIt.isRegistered(instance: feature)) {
        continue;
      }
      logger?.finest('$feature: registering feature');

      getIt.registerSingleton(
        feature,
        dispose: (_) => feature.dispose(),
      );

      logger?.finer('$feature: registered feature');
    }
  }

  void _ensureFeatureTypesRegistered(Feature feature) {
    final installStatus = _featureStatuses[feature.runtimeType];
    if (installStatus == null) {
      throw Exception('Feature $feature is not known...');
    }
    if (installStatus.hasRegisteredTypes) {
      return;
    }

    logger?.finest('$feature: registering types of feature');

    feature.registerTypes(getIt);
    _featureStatuses[feature.runtimeType] = installStatus
      ..hasRegisteredTypes = true;

    logger?.finer('$feature: registered types of feature');
  }

  Future<void> install() async {
    while (!_featureStatuses.values.every((status) => status.isInstalled)) {
      final installFutures = features
          .where(_canFeatureBeInstalled)
          .map(_ensureFeatureInstalled)
          .toList(growable: false);

      await Future.wait(installFutures);

      if (installFutures.isEmpty) {
        throwCircularDependencyException();
        return;
      }
    }
  }

  Future<void> _ensureFeatureInstalled(Feature feature) async {
    final status = _featureStatuses[feature.runtimeType];
    if (status == null) {
      throw Exception(
        'First register the types, then call install. The installation method '
        'will need some of the types which are being registered in the '
        'registerTypes method.',
      );
    }
    if (status.isInstalled) {
      return;
    }

    if (!_canFeatureBeInstalled(feature)) {
      throw Exception(
        'Cannot install feature... maybe some dependent feature is not yet '
        'installed?',
      );
    }

    logger?.finest('$feature: installing feature');

    await feature.install(getIt);
    _featureStatuses[feature.runtimeType] = status..isInstalled = true;

    logger?.fine('$feature: installed feature');
  }

  bool _canFeatureBeInstalled(Feature feature) {
    final status = _featureStatuses[feature.runtimeType];
    return status == null ||
        (!status.isInstalled &&
            feature.dependencies
                .map((type) => _featureStatuses[type])
                .every((status) {
              if (status == null) {
                throw Exception('Feature $feature is not known...');
              }
              return status.isInstalled;
            }));
  }

  T throwCircularDependencyException<T>() {
    final leftOverFeatures = _featureStatuses.keys
        .where((type) => _featureStatuses[type]?.isInstalled != true)
        .toList(growable: false);
    throw Exception(
      'Circular dependency between features detected. Left over features: '
      '$leftOverFeatures',
    );
  }
}

class _FeatureStatus {
  _FeatureStatus(this.feature);

  final Feature feature;

  bool isInstalled = false;
  bool hasRegisteredTypes = false;
}

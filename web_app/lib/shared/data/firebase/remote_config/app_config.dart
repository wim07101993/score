import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.g.dart';

class AppConfig {
  const AppConfig({
    required this.algolia,
  });

  final AlgoliaConfig algolia;
}

@JsonSerializable()
class AlgoliaConfig {
  const AlgoliaConfig({
    required this.apiKey,
    required this.appId,
  });

  factory AlgoliaConfig.fromJson(Map<String, dynamic> json) {
    return _$AlgoliaConfigFromJson(json);
  }

  final String apiKey;
  final String appId;
}

import 'package:score/helpers/json_map_extensions.dart';

class const Creators({
  final List<String> composers = const [],
  final List<String> lyricists = const [],
}) {
  factory Creators.fromJson(Map json) {
    return Creators(
      composers: json.getList<String>('composers'),
      lyricists: json.getList<String>('lyricists'),
    );
  }

  Map<String, Object?> toJson() => {
    'composers': composers,
    'lyricists': lyricists,
  };
}

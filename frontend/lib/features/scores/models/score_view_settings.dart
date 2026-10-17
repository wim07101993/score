import 'package:score/helpers/json_map_extensions.dart';

class ScoreViewSettings {
  ScoreViewSettings({
    required int transposition,
    required Map<String, bool> partVisibilities,
    required double zoom,
  }) : this._(
         transposition: transposition.clamp(minTransposition, maxTransposition),
         partVisibilities: partVisibilities,
         zoom: zoom.clamp(minZoom, maxZoom),
       );

  const ScoreViewSettings._({
    required this.transposition,
    required this.partVisibilities,
    required this.zoom,
  });

  const ScoreViewSettings.defaultView()
    : this._(
        transposition: 0,
        partVisibilities: const {},
        zoom: 1,
      );

  factory ScoreViewSettings.fromJson(Map json) {
    return ScoreViewSettings(
      transposition:
          json.get('transposition', parser: int.tryParse) ??
          defaultTransposition,
      partVisibilities:
          json.getObject(
            'part_visibilities',
            (m) => m as Map<String, bool>?,
          ) ??
          const {},
      zoom:
          json.get<num>('zoom', parser: num.tryParse)?.toDouble() ??
          defaultZoom,
    );
  }

  static const int defaultTransposition = 0;
  static const double defaultZoom = 1;

  static const double minZoom = 0.5;
  static const double maxZoom = 4;

  static const int maxTransposition = 12;
  static const int minTransposition = -12;

  final int transposition;
  final Map<String, bool> partVisibilities;
  final double zoom;

  Map<String, Object?> toJson() => {
    'transposition': transposition,
    'part_visibilities': partVisibilities,
    'zoom': zoom,
  };
}

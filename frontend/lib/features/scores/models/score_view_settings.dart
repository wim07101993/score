import 'package:score/json_map_extensions.dart';

class ScoreViewSettings {
  ScoreViewSettings({
    required int transposition,
    required List<String> hiddenParts,
    required double zoom,
  }) : this._(
         transposition: transposition.clamp(minTransposition, maxTransposition),
         hiddenParts: hiddenParts,
         zoom: zoom.clamp(minZoom, maxZoom),
       );

  const ScoreViewSettings._({
    required this.transposition,
    required this.hiddenParts,
    required this.zoom,
  });

  const ScoreViewSettings.defaultView()
    : this._(
        transposition: 0,
        hiddenParts: const [],
        zoom: 1,
      );

  factory ScoreViewSettings.fromJson(Map json) {
    return ScoreViewSettings(
      transposition:
          json.get('transposition', parser: int.tryParse) ??
          defaultTransposition,
      hiddenParts: json.getList('hidden_parts'),
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
  final List<String> hiddenParts;
  final double zoom;

  Map<String, Object?> toJson() => {
    'transposition': transposition,
    'hidden_parts': hiddenParts,
    'zoom': zoom,
  };
}

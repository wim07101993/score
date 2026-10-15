import 'package:score/helpers/json_map_extensions.dart';

class const Movement({
  final String? title,
  final String? number,
}) {
  static Movement? fromJson(Map json) {
    return Movement(
      title: json.get('title'),
      number: json.get('number'),
    );
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'number': number,
  };
}

import 'package:score/helpers/json_map_extensions.dart';

class const Work({
  final String? title,
  final String? number,
}) {
  static Work? fromJson(Map json) {
    return Work(
      title: json.get('title'),
      number: json.get('number'),
    );
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'number': number,
  };
}

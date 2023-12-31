import 'package:xml/xml.dart';

Future<void> parseMusicXml(String xml) async {
  final music = XmlDocument.parse(xml);
  final x = music.getElement('score-partwise');
}

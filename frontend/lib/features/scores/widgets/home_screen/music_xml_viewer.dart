import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlViewer extends StatefulWidget {
  const MusicXmlViewer({super.key});

  @override
  State<MusicXmlViewer> createState() => _MusicXmlViewerState();
}

class _MusicXmlViewerState extends State<MusicXmlViewer> {
  WebViewController webViewController = WebViewController();
  String? htmlPage;

  @override
  void initState() {
    super.initState();
    createHtmlPage();
  }

  Future<void> createHtmlPage() async {}
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

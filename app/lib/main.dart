import 'package:flutter/material.dart';

import 'app.dart';
import 'dc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance..init();

  runApp(App(getIt: getIt));
}

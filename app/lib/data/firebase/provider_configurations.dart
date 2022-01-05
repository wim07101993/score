import 'dart:io';

import 'package:flutterfire_ui/auth.dart';
import 'package:score/data/firebase/firebase_options.dart';

class ProviderConfigurations {
  const ProviderConfigurations({
    this.email = true,
    this.google = true,
  });

  final bool email;
  final bool google;

  List<ProviderConfiguration> call() {
    return [
      if (email) const EmailProviderConfiguration(),
      if (Platform.isAndroid && google)
        GoogleProviderConfiguration(
          clientId: DefaultFirebaseOptions.currentPlatform.appId,
        ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/data/firebase/provider_configurations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logger = context.read<GetIt>().logger('logger');
    logger.info('this works');

    return SignInScreen(
      providerConfigs: context.read<ProviderConfigurations>()(),
    );
  }
}

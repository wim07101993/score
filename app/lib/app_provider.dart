import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:score/data/firebase/provider_configurations.dart';
import 'package:score/data/logging/hive_log_sink.dart';
import 'package:score/features/user/change_notifiers/is_signed_in_notifier.dart';
import 'package:score/features/user/change_notifiers/roles_notifier.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/globals.dart';

class AppProvider extends StatelessWidget {
  const AppProvider({
    Key? key,
    required this.getIt,
    required this.child,
  }) : super(key: key);

  final GetIt getIt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => S.of(context) ?? SEn()),
        Provider.value(value: getIt),
        Provider.value(value: getIt<HiveLogSink>()),
        Provider.value(value: getIt<ProviderConfigurations>()),
        Provider.value(value: getIt<FirebaseAuth>()),
        ChangeNotifierProvider.value(value: getIt<UserNotifier>()),
        ChangeNotifierProvider(create: (_) => getIt<IsSignedInNotifier>()),
        ChangeNotifierProvider(create: (_) => getIt<RolesNotifier>()),
      ],
      child: child,
    );
  }
}

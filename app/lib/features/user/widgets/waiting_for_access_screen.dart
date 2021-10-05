import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';
import 'package:score/app_router.gr.dart';
import 'package:score/data/firebase/user/access_levels.dart';

import 'waiting_for_access_screen/header.dart';

class WaitingForAccessScreen extends StatefulWidget {
  const WaitingForAccessScreen({Key? key}) : super(key: key);

  @override
  _WaitingForAccessScreenState createState() => _WaitingForAccessScreenState();
}

class _WaitingForAccessScreenState extends State<WaitingForAccessScreen> {
  late final AccessLevelsChanges accessLevelsChanges;

  @override
  void initState() {
    super.initState();
    accessLevelsChanges = context.read<AccessLevelsChanges>();
    accessLevelsChanges.addListener(_onAccessLevelsChanged);
  }

  @override
  void dispose() {
    super.dispose();
    accessLevelsChanges.removeListener(_onAccessLevelsChanged);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          const Expanded(child: Header()),
          Center(
            child: Text(
              'You do not yet have permissions to visit the application. Ask Wim for access.',
              style: theme.textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _onAccessLevelsChanged() {
    if (accessLevelsChanges.value.application) {
      AutoRouter.of(context).replace(const HomeRoute());
    }
  }
}

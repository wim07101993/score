import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/widgets/account_header_card.dart';
import 'package:score/features/auth/widgets/authentication_details.dart';
import 'package:score/features/auth/widgets/permissions_card.dart';
import 'package:score/features/auth/widgets/signed_out_card.dart';

@RoutePage()
class const ProfilePage({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: GetIt.I<AuthNotifier>(),
      builder: (context, user, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user == null)
              const SignedOut()
            else ...[
              AccountHeaderCard(user: user),
              const SizedBox(height: 16),
              PermissionsCard(user: user),
            ],
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: const Icon(Icons.build_outlined),
                title: const Text('Technical details'),
                subtitle: const Text('For when something does not work'),
                childrenPadding: const EdgeInsets.all(12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [AuthenticationDetails(user: user)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

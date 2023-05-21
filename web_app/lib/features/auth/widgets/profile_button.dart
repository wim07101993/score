import 'package:flutter/material.dart';
import 'package:score/features/auth/behaviours/logout.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton(
      color: theme.primaryColor,
      icon: const Icon(Icons.account_circle, size: 32),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: context.getIt<Logout>(),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}

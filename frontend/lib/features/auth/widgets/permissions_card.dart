import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';

class const PermissionsCard({
  required final UserInfo user,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Permissions',
                style: theme.textTheme.titleMedium,
              ),
            ),
            _permission(
              theme,
              allowed: user.isScoreViewer,
              label: 'See scores and sets',
            ),
            _permission(
              theme,
              allowed: user.isScoreEditor,
              label: 'Upload and change scores',
            ),
            if (!user.isScoreViewer || !user.isScoreEditor)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Need more? Ask whoever manages Score to give you access.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _permission(
    ThemeData theme, {
    required bool allowed,
    required String label,
  }) {
    return ListTile(
      leading: Icon(
        allowed ? Icons.check_circle : Icons.cancel_outlined,
        color: allowed ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(label),
      subtitle: Text(allowed ? 'Allowed' : 'Not allowed'),
    );
  }
}

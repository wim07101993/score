import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';

class const AccountHeaderCard({
  required final UserInfo user,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user.name;
    final email = user.email;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                _initials(name ?? email ?? '?'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? 'No name',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final words = name
        .split(RegExp(r'[\s@.]+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .toList(growable: false);
    return words.isEmpty ? '?' : words.join();
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../app.dart';

/// What this app has been told about the user, and by whom.
///
/// Every page decides what to show from the roles the provider sent — a page
/// that shows nothing is a page that was told nothing, and there has to be
/// somewhere to see what that was. So this shows the answer as it came back
/// rather than what this app made of it: the claim the roles were looked for
/// under, the claims that actually arrived, and whether they came from the
/// provider or from the copy this device kept.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _asking = false;
  bool? _providerReachable;
  bool? _apiReachable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    final app = AppScope.read(context);
    // Both of these are a round trip, and the rest of the page is worth showing
    // before they come back.
    final results = await Future.wait([
      app.oidc.canBeReached(),
      app.scoresApi.canBeReached(),
    ]);
    if (mounted) {
      setState(() {
        _providerReachable = results[0];
        _apiReachable = results[1];
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _asking = true);
    await AppScope.read(context).updateAuth();
    await _ask();
    if (mounted) setState(() => _asking = false);
  }

  Future<void> _signOutHere() async {
    await AppScope.read(context).forgetUser();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.user;
    final rolesKey = user?.rolesKey ?? app.config.oidc.rolesKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_asking) const LinearProgressIndicator(),
          _Section(
            title: 'You',
            rows: [
              ('Name', user?.name),
              ('Email', user?.email),
              ('Subject', user?.subject),
            ],
            footer: user == null
                ? 'Nobody is signed in on this device.'
                : app.userIsFromThisDevice
                    ? 'The provider could not be reached, so this is the copy'
                        ' this device kept the last time it could ask. Your'
                        ' roles may have changed since.'
                    : 'Asked of the provider just now.',
          ),
          _Section(
            title: 'What you may do',
            rows: [
              ('See scores and sets', _yesNo(user?.isScoreViewer == true)),
              ('Upload scores', _yesNo(user?.isScoreEditor == true)),
              ('Roles claim', rolesKey),
              (
                'Roles found',
                user?.roles == null ? null : user!.roles!.keys.join(', ')
              ),
            ],
            footer: _rolesExplanation(user?.roles, user?.claims, rolesKey),
          ),
          _Section(
            title: 'Where it is pointed',
            rows: [
              ('API', '${app.config.api.baseUrl}'),
              ('API reachable', _asked(_apiReachable)),
              ('Provider', '${app.config.oidc.authorizationEndpoint}'),
              ('Provider reachable', _asked(_providerReachable)),
              ('Client id', app.config.oidc.clientId),
              ('Redirect (web)', '${app.config.oidc.redirectUri}'),
              ('Redirect (device)', '${app.config.oidc.nativeRedirectUri}'),
            ],
          ),
          ListenableBuilder(
            listenable: Listenable.merge([app.scores, app.sets]),
            builder: (context, _) {
              final owing =
                  app.sets.sets.where((set) => set.owesAnything).toList();
              return _Section(
                title: 'On this device',
                rows: [
                  ('Scores', '${app.scores.scores.length}'),
                  ('Sets', '${app.sets.sets.length}'),
                  (
                    'Sets not sent yet',
                    owing.isEmpty
                        ? 'none'
                        : '${owing.length}: '
                            '${owing.map((set) => set.displayTitle).join(', ')}'
                  ),
                ],
              );
            },
          ),
          if (user?.claims != null)
            ExpansionTile(
              title: const Text('What the provider actually sent'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(user!.claims),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonal(
                onPressed: _asking ? null : _refresh,
                child: const Text('Ask the provider again'),
              ),
              OutlinedButton(
                onPressed: _signOutHere,
                child: const Text('Sign in again'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Signing in again forgets the tokens and the roles this device is'
            ' holding. It signs nobody out at the provider — that is the'
            " provider's own business. The scores and sets on this device are"
            ' left alone.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String? _rolesExplanation(
      Map<String, dynamic>? roles, Map<String, dynamic>? claims, String key) {
    if (roles == null) {
      final sent = claims?.keys.toList() ?? const [];
      return sent.isEmpty
          ? 'The provider sent no claims this app could read.'
          : 'The roles are read out of the claim named "$key", and the answer'
              ' does not have one. What it does have: ${sent.join(', ')}.';
    }
    if (roles['score_viewer'] != null) {
      return null;
    }
    return 'The claim "$key" is there, but "score_viewer" is not one of the'
        ' roles in it.';
  }
}

String _yesNo(bool yes) => yes ? 'yes' : 'no';

String _asked(bool? answer) =>
    answer == null ? 'asking…' : (answer ? 'yes' : 'no');

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.footer});

  final String title;
  final List<(String, String?)> rows;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (term, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(term, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: SelectableText(
                        value == null || value.isEmpty ? 'not sent' : value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: value == null || value.isEmpty
                              ? FontStyle.italic
                              : null,
                          color: value == null || value.isEmpty
                              ? theme.colorScheme.outline
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(footer!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

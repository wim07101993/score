import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/behaviours/can_connect_to_api.dart';
import 'package:score/features/auth/behaviours/can_connect_to_oidc_provider.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/auth/widgets/api_reachable_indicator.dart';
import 'package:score/features/auth/widgets/copy_button.dart';
import 'package:score/features/auth/widgets/property.dart';
import 'package:score/features/auth/widgets/refresh_token_button.dart';
import 'package:score/widgets/json_view.dart';

class const AuthenticationDetails({
  super.key,
  required final UserInfo? user,
}) extends StatefulWidget {
  @override
  State<AuthenticationDetails> createState() => _AuthenticationDetailsState();
}

class _AuthenticationDetailsState extends State<AuthenticationDetails> {
  @override
  Widget build(BuildContext context) {
    final config = GetIt.I<Config>();
    final clientConfig = config.oidc.clientConfig;
    final theme = Theme.of(context);

    final userId = widget.user?.id ?? '';
    final roles = widget.user?.roles.keys.join(', ') ?? '';
    final apiBaseUrl = config.api.baseUrl.toString();
    final discoveryEndpoint = config.oidc.discoveryEndpoint.toString();
    final redirectUri = clientConfig.redirectUri.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RefreshTokenButton(),
        const SizedBox(height: 12),
        _sectionTitle(theme, 'Account'),
        Property(
          name: 'User id',
          value: userId,
          trailing: CopyButton(value: userId),
        ),
        Property(
          name: 'User roles',
          value: roles,
          trailing: CopyButton(value: roles),
        ),
        Property(
          name: 'Roles claim',
          value: config.oidc.rolesKey,
          trailing: CopyButton(value: config.oidc.rolesKey),
        ),
        _sectionTitle(theme, 'Connection'),
        Property(
          name: 'API',
          value: apiBaseUrl,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApiReachableIndicator(
                check: () async => await GetIt.I<CanConnectToApi>()(),
              ),
              CopyButton(value: apiBaseUrl),
            ],
          ),
        ),
        Property(
          name: 'OIDC provider',
          value: discoveryEndpoint,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApiReachableIndicator(
                check: () async => await GetIt.I<CanConnectToOidcProvider>()(),
              ),
              CopyButton(value: discoveryEndpoint),
            ],
          ),
        ),
        Property(
          name: 'Client id',
          value: clientConfig.clientId,
          trailing: CopyButton(value: clientConfig.clientId),
        ),
        Property(
          name: 'Redirect URI',
          value: redirectUri,
          trailing: CopyButton(value: redirectUri),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(16),
            child: _idToken(theme),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _idToken(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('ID-token', style: theme.textTheme.titleMedium),
            ),
            CopyButton(value: widget.user?.oidcUser.idToken ?? ''),
          ],
        ),
        const SizedBox(height: 8),
        JsonView(json: widget.user?.oidcUser.claims.toJson()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../models/request_model.dart';
import '../providers/request_provider.dart';

class AuthEditor extends ConsumerWidget {
  const AuthEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authType =
        ref.watch(requestNotifierProvider.select((state) => state.authType));
    final authData = ref.watch(
      requestNotifierProvider.select((state) => state.authData ?? {}),
    );
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTypeCard(
            authType: authType,
            onChanged: (value) {
              ref.read(requestNotifierProvider.notifier).updateAuthType(value);
            },
          ),
          const SizedBox(height: AppTokens.s4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (authType) {
              AuthType.bearer => _BearerFields(
                  key: const ValueKey('bearer-auth'),
                  data: authData,
                  onChanged: (data) {
                    ref
                        .read(requestNotifierProvider.notifier)
                        .updateAuthData(data);
                  },
                ),
              AuthType.basic => _BasicFields(
                  key: const ValueKey('basic-auth'),
                  data: authData,
                  onChanged: (data) {
                    ref
                        .read(requestNotifierProvider.notifier)
                        .updateAuthData(data);
                  },
                ),
              AuthType.apiKey => _ApiKeyFields(
                  key: const ValueKey('api-key-auth'),
                  data: authData,
                  onChanged: (data) {
                    ref
                        .read(requestNotifierProvider.notifier)
                        .updateAuthData(data);
                  },
                ),
              AuthType.none => _AuthEmptyState(theme: theme),
            },
          ),
        ],
      ),
    );
  }
}

class _AuthTypeCard extends StatelessWidget {
  final AuthType authType;
  final ValueChanged<AuthType> onChanged;

  const _AuthTypeCard({
    required this.authType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: _fieldCardDecoration(theme),
      child: Wrap(
        spacing: AppTokens.s3,
        runSpacing: AppTokens.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.s2),
              Text(
                'Authentication',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AuthType>(
                value: authType,
                dropdownColor: theme.cardColor,
                style: theme.textTheme.bodyMedium,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: AuthType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_authLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BearerFields extends StatelessWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const _BearerFields({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthFieldCard(
      title: 'Bearer token',
      description: 'Adds an Authorization: Bearer <token> header.',
      children: [
        _AuthTextField(
          label: 'Token',
          initialValue: data['token'],
          hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          onChanged: (value) => _update('token', value),
        ),
      ],
    );
  }

  void _update(String key, String value) {
    final next = Map<String, String>.from(data);
    next[key] = value;
    onChanged(next);
  }
}

class _BasicFields extends StatelessWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const _BasicFields({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthFieldCard(
      title: 'Basic auth',
      description:
          'Encodes username and password into an Authorization header.',
      children: [
        _ResponsiveFieldRow(
          children: [
            _AuthTextField(
              label: 'Username',
              initialValue: data['username'],
              onChanged: (value) => _update('username', value),
            ),
            _AuthTextField(
              label: 'Password',
              initialValue: data['password'],
              obscureText: true,
              onChanged: (value) => _update('password', value),
            ),
          ],
        ),
      ],
    );
  }

  void _update(String key, String value) {
    final next = Map<String, String>.from(data);
    next[key] = value;
    onChanged(next);
  }
}

class _ApiKeyFields extends StatelessWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const _ApiKeyFields({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthFieldCard(
      title: 'API key',
      description:
          'Injects a custom key/value pair into headers or query params.',
      children: [
        _ResponsiveFieldRow(
          children: [
            _AuthTextField(
              label: 'Key',
              initialValue: data['key'],
              hintText: 'x-api-key',
              onChanged: (value) => _update('key', value),
            ),
            _AuthTextField(
              label: 'Value',
              initialValue: data['value'],
              hintText: 'secret-value',
              onChanged: (value) => _update('value', value),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s3),
        _AddToSelector(
          value: data['addTo'] ?? 'Header',
          onChanged: (value) => _update('addTo', value),
        ),
      ],
    );
  }

  void _update(String key, String value) {
    final next = Map<String, String>.from(data);
    next[key] = value;
    onChanged(next);
  }
}

class _AuthFieldCard extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const _AuthFieldCard({
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      decoration: _fieldCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTokens.s1),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          ...children,
        ],
      ),
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFieldRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppTokens.s3),
                children[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppTokens.s3),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final String? hintText;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  const _AuthTextField({
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        TextFormField(
          initialValue: initialValue,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hintText),
          style: AppTokens.monoStyle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AddToSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _AddToSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: theme.cardColor,
              style: theme.textTheme.bodyMedium,
              isExpanded: true,
              isDense: true,
              items: ['Header', 'Query Params']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthEmptyState extends StatelessWidget {
  final ThemeData theme;

  const _AuthEmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s5),
      decoration: _fieldCardDecoration(theme),
      child: Column(
        children: [
          Icon(
            Icons.lock_open_outlined,
            size: 34,
            color: theme.colorScheme.primary.withValues(alpha: 0.62),
          ),
          const SizedBox(height: AppTokens.s3),
          Text(
            'No authentication selected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTokens.s1),
          Text(
            'Choose Bearer, Basic, or API Key when this request requires credentials.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _fieldCardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.025),
      theme.colorScheme.surface,
    ),
    border: Border.all(color: theme.dividerColor),
    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
  );
}

String _authLabel(AuthType type) {
  switch (type) {
    case AuthType.none:
      return 'No Auth';
    case AuthType.bearer:
      return 'Bearer Token';
    case AuthType.basic:
      return 'Basic Auth';
    case AuthType.apiKey:
      return 'API Key';
  }
}

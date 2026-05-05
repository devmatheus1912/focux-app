import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'fx_icon.dart';

class FxEmptyAction {
  final String label;
  final VoidCallback onTap;

  const FxEmptyAction({required this.label, required this.onTap});
}

class FxEmptyState extends StatelessWidget {
  const FxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final FxEmptyAction? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(EagleTokens.radiusLg),
              ),
              child: Center(
                child: FxIcon(name: icon, size: 28, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              TextButton(onPressed: action!.onTap, child: Text(action!.label)),
            ],
          ],
        ),
      ),
    );
  }
}

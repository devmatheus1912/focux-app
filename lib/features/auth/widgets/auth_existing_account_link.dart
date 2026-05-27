import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';

/// Link acessível (48dp) para login — registro e onboarding.
class AuthExistingAccountLink extends StatelessWidget {
  const AuthExistingAccountLink({
    super.key,
    required this.role,
    this.leadingText = FocuxBrandCopy.authExistingAccountLead,
    this.actionText = FocuxBrandCopy.authExistingAccountAction,
  });

  final String role;
  final String leadingText;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: '$leadingText$actionText',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/login?role=$role'),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.inter(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: leadingText),
                    TextSpan(
                      text: actionText,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

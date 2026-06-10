import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../constants/aluno_360_layout.dart';

class Aluno360EmptyMiniState extends StatelessWidget {
  const Aluno360EmptyMiniState({
    super.key,
    required this.icon,
    required this.text,
    required this.isDark,
    this.semanticsLabel,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final shell = Container(
      padding: Aluno360Layout.emptyMiniStatePadding,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Aluno360Layout.panelTitleStyle(context, mute),
            ),
          ),
        ],
      ),
    );
    final label = semanticsLabel ?? text;
    return Semantics(label: label, child: shell);
  }
}

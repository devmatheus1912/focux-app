import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class ConversationAttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const ConversationAttachOption({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s4,
          vertical: TokensStrip.s3,
        ),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          children: [
            Icon(icon, color: primary),
            const SizedBox(width: TokensStrip.s3),
            Text(
              label,
              style: FocuxHubTypography.body(
                color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationReplyComposerBar extends StatelessWidget {
  final bool isDark;
  final String sender;
  final String preview;
  final VoidCallback onClose;

  const ConversationReplyComposerBar({
    super.key,
    required this.isDark,
    required this.sender,
    required this.preview,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        TokensStrip.s2,
        TokensStrip.s2,
        TokensStrip.s2,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s3,
        TokensStrip.s2,
        TokensStrip.s2,
        TokensStrip.s2,
      ),
      decoration: fxListCardDecoration(context, accent: accentColor),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: FocuxHubTypography.chip(accentColor),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class ConversationSearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ConversationSearchState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: TokensStrip.textSecondary),
            const SizedBox(height: TokensStrip.s2),
            Text(
              title,
              style: FocuxHubTypography.body(
                color: TokensStrip.textPrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(
                color: TokensStrip.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationRecordingComposerBar extends StatelessWidget {
  final bool isDark;
  final String duration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const ConversationRecordingComposerBar({
    super.key,
    required this.isDark,
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        TokensStrip.s2,
        TokensStrip.s2,
        TokensStrip.s2,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s3,
        TokensStrip.s2,
        TokensStrip.s2,
        TokensStrip.s2,
      ),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: EagleTokens.bad,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Text(
              'Gravando $duration',
              style: FocuxHubTypography.body(color: ink).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancelar áudio',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline_rounded, color: mute),
          ),
          IconButton(
            tooltip: 'Enviar áudio',
            visualDensity: VisualDensity.compact,
            onPressed: onSend,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }
}

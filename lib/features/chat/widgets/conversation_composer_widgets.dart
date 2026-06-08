import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class ConversationAttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const ConversationAttachOption({super.key, 
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          children: [
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Text(label),
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

  const ConversationReplyComposerBar({super.key, 
    required this.isDark,
    required this.sender,
    required this.preview,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                    fontSize: 12,
                  ),
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

  const ConversationSearchState({super.key, 
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
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TokensStrip.textSecondary),
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

  const ConversationRecordingComposerBar({super.key, 
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
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFE5484D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gravando $duration',
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancelar audio',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline_rounded, color: mute),
          ),
          IconButton(
            tooltip: 'Enviar audio',
            visualDensity: VisualDensity.compact,
            onPressed: onSend,
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
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


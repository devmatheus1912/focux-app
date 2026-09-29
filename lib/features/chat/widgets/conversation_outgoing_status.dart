import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/chat_outbox.dart';

String chatOutgoingStatusLabel(ChatOutgoingStatus status, S s) {
  return switch (status) {
    ChatOutgoingStatus.sending => s.chatStatusEnviando,
    ChatOutgoingStatus.failed => s.chatStatusNaoEnviada,
    ChatOutgoingStatus.sent => s.chatStatusEnviado,
    ChatOutgoingStatus.delivered => s.chatStatusEntregue,
    ChatOutgoingStatus.read => s.chatStatusLido,
  };
}

class ConversationDeliveryStatus extends StatelessWidget {
  final ChatOutgoingStatus status;
  final Color color;

  const ConversationDeliveryStatus({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final label = chatOutgoingStatusLabel(status, S.of(context));
    if (status != ChatOutgoingStatus.failed) {
      return Text(label, style: FocuxHubTypography.chip(color));
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 12,
            color: EagleTokens.bad,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: FocuxHubTypography.chip(
              EagleTokens.bad,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Ações da bolha que não chegou ao servidor: reenviar ou tirar da conversa.
class ConversationSendFailedActions extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const ConversationSendFailedActions({
    super.key,
    required this.accentColor,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final style = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onRetry,
          style: style,
          icon: Icon(Icons.refresh_rounded, size: 16, color: accentColor),
          label: Text(s.retry, style: FocuxHubTypography.chip(accentColor)),
        ),
        TextButton(
          onPressed: onDiscard,
          style: style,
          child: Text(
            s.chatApagarNaoEnviada,
            style: FocuxHubTypography.chip(chrome.mute),
          ),
        ),
      ],
    );
  }
}

class ConversationUploadingBanner extends StatelessWidget {
  final Color primary;
  final Color background;
  final bool isDark;

  const ConversationUploadingBanner({
    super.key,
    required this.primary,
    required this.background,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: background,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: FxLoading(strokeWidth: 2, color: primary),
          ),
          const SizedBox(width: 10),
          Text(
            S.of(context).chatEnviandoAnexo,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

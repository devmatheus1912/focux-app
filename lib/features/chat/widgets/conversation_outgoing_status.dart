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
    final bad =
        ShellChrome.of(context).isDark
            ? EagleTokens.badDark
            : EagleTokens.badInk;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 12, color: bad),
          const SizedBox(width: 3),
          Text(
            label,
            style: FocuxHubTypography.chip(
              bad,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Ações da bolha que não chegou ao servidor: reenviar ou tirar da conversa.
/// Sem [onRetry] (outro anexo subindo), o reenvio aparece desabilitado.
class ConversationSendFailedActions extends StatelessWidget {
  final Color accentColor;
  final VoidCallback? onRetry;
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
    final canRetry = onRetry != null;
    final style = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MergeSemantics(
          child: Semantics(
            hint: canRetry ? null : s.chatReenvioAguardaAnexo,
            child: TextButton.icon(
              onPressed: onRetry,
              style: style,
              icon: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: canRetry ? accentColor : chrome.mute,
              ),
              label: Text(
                s.retry,
                style: FocuxHubTypography.chip(
                  canRetry ? chrome.ink : chrome.mute,
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onDiscard,
          style: style,
          child: Text(
            s.chatDescartarNaoEnviada,
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

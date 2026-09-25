import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/money/fx_money.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/pacote_repository.dart';
import '../utils/pacote_display.dart';

part 'pacotes_storefront_widgets_private.part.dart';

/// Confirma desativação antes de remover da vitrine.
Future<bool> confirmDesativarPacote(BuildContext context, String titulo) {
  return showFxConfirmSheet(
    context,
    title: pacoteDesativarConfirmTitle(),
    message: pacoteDesativarConfirmMessage(titulo),
    icon: Icons.delete_outline_rounded,
    confirmLabel: pacoteDesativarConfirmLabel(),
    destructive: true,
  );
}

/// Skeleton de carregamento — alinhado ao Setup D0.
class PacotesStorefrontSkeleton extends StatelessWidget {
  const PacotesStorefrontSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 132,
              margin: const EdgeInsets.only(bottom: TokensStrip.s3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
            ),
        ],
      ),
    );
  }
}

/// Resumo dinâmico — contagem e ticket médio.
class PacotesOverviewStrip extends StatelessWidget {
  const PacotesOverviewStrip({super.key, required this.pacotes});

  final List<Pacote> pacotes;

  @override
  Widget build(BuildContext context) {
    if (pacotes.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = pacotes.length;
    final ticketSoma = pacotes
        .map((p) => p.valor)
        .reduce((a, b) => a + b);
    final ticketMedio = FxMoney.cents(ticketSoma.cents ~/ count);
    final ticketLabel = ticketMedio.format(showDecimals: true).replaceFirst('R\$', '').trim();

    return Semantics(
      label:
          '$count ${count == 1 ? 'plano ativo' : 'planos ativos'}, preço médio R\$ $ticketLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: TokensStrip.s3),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s3,
        ),
        decoration: BoxDecoration(
          color: TokensStrip.glassFill(dark: isDark),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: TokensStrip.glassBorder(dark: isDark)),
        ),
        child: Text(
          '$count ${count == 1 ? 'plano ativo' : 'planos ativos'} · preço médio R\$ $ticketLabel',
          style: FocuxHubTypography.cardTitle(color: fxScreenInk(context)),
        ),
      ),
    );
  }
}

/// Empty state alinhado ao Setup D0 — delega ao canônico [FxEmptyState].
class PacotesEmptyState extends StatelessWidget {
  const PacotesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const FxEmptyState(
      icon: 'coin',
      title: 'Crie seu primeiro plano',
      subtitle:
          'Um plano tem nome, preço e o que está incluso (treino, consultoria…). '
          'Ele aparece na sua página quando alguém abrir seu link.\n\n'
          'Ex.: Musculação · 3 meses · R\$ 500',
    );
  }
}

/// Card de pacote na lista.
class PacoteStorefrontCard extends StatelessWidget {
  const PacoteStorefrontCard({
    super.key,
    required this.pacote,
    required this.onDelete,
    this.entranceIndex = 0,
  });

  final Pacote pacote;
  final VoidCallback onDelete;
  final int entranceIndex;

  Future<void> _abrirMenu(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await showFxInsetPickerSheet<bool>(
      context,
      title: pacote.titulo,
      items: const [
        FxInsetPickerSheetItem(
          value: true,
          label: 'Desativar plano',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    );
    if (picked == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s3),
      decoration: fxStripCardDecoration(
        context,
        accent: pacote.destaque ? primary : null,
        glowStrength: pacote.destaque ? 0.55 : 0.38,
      ),
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s3,
        TokensStrip.s1,
        TokensStrip.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  pacote.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.cardTitle(color: ink),
                ),
              ),
              if (pacote.destaque) _PacoteDestaqueBadge(accent: primary),
              IconButton(
                tooltip: 'Mais opções de ${pacote.titulo}',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: () => _abrirMenu(context),
                icon: Icon(Icons.more_vert_rounded, color: mute),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: TokensStrip.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pacote.descricao != null && pacote.descricao!.isNotEmpty) ...[
                  Text(
                    pacote.descricao!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                  const SizedBox(height: TokensStrip.s1),
                ],
                Text(
                  pacoteResumoLinha(
                    treino: pacote.incluiTreino,
                    consultoria: pacote.incluiConsultoria,
                    meses: pacote.duracaoMeses,
                  ),
                  style: FocuxHubTypography.bodyMuted(
                    color: mute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                Text(
                  pacote.valor.format(),
                  style: FocuxHubTypography.metric(
                    color: ink,
                    fontSize: FocuxHubTypography.metricLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (reduceMotionOf(context)) return card;
    return card
        .animate(delay: Duration(milliseconds: entranceIndex * 70))
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.03, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}

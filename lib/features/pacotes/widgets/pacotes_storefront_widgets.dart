import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/pacote_repository.dart';
import '../utils/pacote_display.dart';

part 'pacotes_storefront_widgets_private.part.dart';

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
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 132,
              margin: const EdgeInsets.only(bottom: TokensStrip.s3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
            ),
          ],
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

    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final count = pacotes.length;
    final ticketMedio =
        pacotes.map((p) => p.valor).reduce((a, b) => a + b) / count;
    final ticketLabel = ticketMedio.toStringAsFixed(2).replaceAll('.', ',');

    return Semantics(
      label:
          '$count ${count == 1 ? 'plano ativo' : 'planos ativos'}, preço médio R\$ $ticketLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: TokensStrip.s3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          border: Border.all(color: primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'plano ativo' : 'planos ativos'} · preço médio R\$ $ticketLabel',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explica o fluxo em linguagem simples — sem jargão de “vitrine”.
class PacotesComoFuncionaCard extends StatelessWidget {
  const PacotesComoFuncionaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s3),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como funciona',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você monta planos com preço (ex.: musculação, 3 meses, R\$ 500). '
                  'Eles ficam numa página sua na internet. Envie o link no WhatsApp ou '
                  'Instagram — a pessoa vê seus planos e pode te contratar.',
                  style: TokensStrip.bodyMuted(
                    color: mute,
                  ).copyWith(fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card premium do link público da storefront.
class StorefrontLinkCard extends StatelessWidget {
  const StorefrontLinkCard({
    super.key,
    required this.slug,
    required this.onCopy,
    required this.onPreview,
  });

  final String slug;
  final VoidCallback onCopy;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final label = Env.landingPageDisplayLabel(slug);

    return Semantics(
      container: true,
      label: 'Link da sua página de vendas na internet, $label',
      child: Container(
        decoration: fxStripCardDecoration(context, accent: primary),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.public_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua página na internet',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Como um cartão de visitas online: o cliente abre o link, '
                        'vê seus planos e valores e pode te chamar.',
                        style: TokensStrip.bodyMuted(
                          color: mute,
                        ).copyWith(fontSize: 12.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Link para enviar no WhatsApp ou Instagram',
              style: TokensStrip.bodyMuted(
                color: mute,
              ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : TokensStrip.pageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : TokensStrip.borderDefault,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  fxIcon: 'article',
                  label: 'Ver como cliente',
                  value: 'Abrir',
                  showDivider: false,
                  onTap: onPreview,
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onCopy,
                child: const Text('Copiar link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state alinhado ao Setup D0 — delega ao canônico [FxEmptyState].
class PacotesEmptyState extends StatelessWidget {
  const PacotesEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return FxEmptyState(
      icon: 'coin',
      title: 'Crie seu primeiro plano',
      subtitle:
          'Um plano tem nome, preço e o que está incluso (treino, nutrição…). '
          'Ele aparece na sua página quando alguém abrir seu link.\n\n'
          'Ex.: Musculação · 3 meses · R\$ 500',
      action: FxEmptyAction(label: 'Criar plano', onTap: onCreate),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pacote.destaque) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DESTAQUE NA PÁGINA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  pacote.titulo,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Desativar pacote ${pacote.titulo}',
                child: IconButton(
                  tooltip: 'Desativar pacote',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: mute),
                ),
              ),
            ],
          ),
          if (pacote.descricao != null && pacote.descricao!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              pacote.descricao!,
              style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (pacote.incluiTreino) const _PacoteTag('Treino'),
              if (pacote.incluiNutri) const _PacoteTag('Nutrição'),
              if (pacote.incluiConsultoria) const _PacoteTag('Consultoria'),
              _PacoteTag(
                '${pacote.duracaoMeses} ${pacote.duracaoMeses == 1 ? 'mês' : 'meses'}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'R\$ ${pacote.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: FocuxHubTypography.metric(
              color: primary,
              fontSize: FocuxHubTypography.metricLg,
              fontWeight: FontWeight.w900,
            ).copyWith(letterSpacing: -0.6),
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

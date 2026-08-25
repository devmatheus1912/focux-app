import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_finance_empty.dart';

class DashboardFinancialHeroSection extends StatelessWidget {
  const DashboardFinancialHeroSection({
    super.key,
    required this.reduceMotion,
    required this.themeDark,
    required this.heroPrimary,
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.loadingFin,
    required this.counterAnim,
    required this.finData,
    required this.receitaTrend,
  });

  final bool reduceMotion;
  final bool themeDark;
  final Color heroPrimary;
  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final bool loadingFin;
  final Animation<double> counterAnim;
  final FinanceiroDashboard? finData;
  final List<double> receitaTrend;

  bool get _compactZeroRevenue => receitaAtual <= 0 && !loadingFin;

  String _metaLine() {
    final meta = finData?.previsaoReceita ?? 0;
    final ticket = finData?.ticketMedio ?? 0;
    if (meta > 0) {
      return 'Meta R\$ ${meta.toStringAsFixed(0)}';
    }
    if (receitaAtual > 0 && ticket > 0) {
      return 'Ticket médio R\$ ${ticket.toStringAsFixed(0)} · defina meta no financeiro';
    }
    return 'Defina a meta mensal no financeiro';
  }

  bool get _showTicketMedio {
    final ticket = finData?.ticketMedio ?? 0;
    return receitaAtual > 0 && ticket > 0;
  }

  Widget _receitaAmount(BuildContext context, Color ink) {
    final style = FocuxHubTypography.metric(
      color: ink,
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1,
    );
    if (loadingFin) {
      final chrome = ShellChrome.of(context);
      return Shimmer.fromColors(
        baseColor: chrome.line,
        highlightColor: chrome.mute.withValues(alpha: 0.35),
        child: Container(
          width: 160,
          height: 36,
          decoration: BoxDecoration(
            color: chrome.cardFill,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (reduceMotion) {
      return Text(
        'R\$ ${receitaAtual.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
        style: style,
      );
    }
    return AnimatedBuilder(
      animation: counterAnim,
      builder:
          (ctx, _) => Text(
            'R\$ ${counterAnim.value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
            style: style,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_compactZeroRevenue) {
      return DashboardFinanceEmptyState(
        mes: mes,
        ctaLabel: finData?.zeroCta,
        onOpen: () => context.go('/financeiro'),
      );
    }

    final chrome = ShellChrome.of(context);
    return Semantics(
      label:
          'Panorama financeiro de $mes. '
          'Recebido R\$ ${receitaAtual.toInt()}. '
          'Toque para abrir financeiro',
      button: true,
      child: InkWell(
        onTap: () => context.go('/financeiro'),
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        child: Ink(
          decoration: fxStripCardDecoration(
            context,
            accent: heroPrimary,
            radius: FxSettingsLayout.groupRadius,
            glowStrength: themeDark ? 0.06 : 0.08,
          ),
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s3,
            TokensStrip.s4,
            TokensStrip.s3,
          ),
          child: _buildFullContent(context, chrome),
        ),
      ),
    );
  }

  Widget _buildFullContent(BuildContext context, ShellPalette chrome) {
    final brand = BrandPalette.sectionAccent(heroPrimary, dark: themeDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receita recebida · $mes',
          style: FocuxHubTypography.bodyMuted(
            color: chrome.mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metaSuperada
              ? 'Meta superada · receita acima do previsto.'
              : pendente > 0
              ? 'Recebido agora. Faltam R\$ ${pendente.toInt()} para a meta.'
              : 'Recebido agora. Meta do mês sob controle.',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute, height: 1.35),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _receitaAmount(context, chrome.ink),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 5),
              child: Text(
                'recebido',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                _metaLine(),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
            if (metaSuperada)
              Text(
                'Superada',
                style: FocuxHubTypography.chip(brand).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (receitaTrend.isNotEmpty) ...[
          Builder(
            builder: (ctx) {
              final hasReceita = receitaTrend.any((v) => v > 0);
              if (!hasReceita) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Histórico mensal aparece ao registrar cobranças',
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  label: 'Tendência de receita nos últimos meses',
                  child: Row(
                    children: [
                      Text(
                        'Receita · últimos meses',
                        style: FocuxHubTypography.bodyMuted(
                          color: chrome.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      FxSparkline(
                        data: receitaTrend,
                        color: brand,
                        width: 96,
                        height: 26,
                        fill: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progressRaw.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: chrome.line,
                  color: brand,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              financePercentLabel(progressRaw, exceeded: metaSuperada),
              style: FocuxHubTypography.metric(
                color: chrome.ink,
                fontSize: TokensStrip.fontBodySm,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s3),
        Text(
          'Pendente R\$ ${pendente.toInt()}'
          ' · ${financeInadimplLabel(MediaQuery.sizeOf(context).width)}'
          ' ${finData?.totalInadimplentes ?? 0}'
          '${_showTicketMedio ? ' · Ticket R\$ ${finData!.ticketMedio.toStringAsFixed(0)}' : ''}',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute, height: 1.35),
        ),
      ],
    );
  }
}

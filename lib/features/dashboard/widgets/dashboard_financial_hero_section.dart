import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_hero_widgets.dart';

class DashboardFinancialHeroSection extends StatelessWidget {
  const DashboardFinancialHeroSection({
    super.key,
    required this.gradientCtrl,
    required this.reduceMotion,
    required this.themeDark,
    required this.heroPrimary,
    required this.heroDeep,
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

  final AnimationController gradientCtrl;
  final bool reduceMotion;
  final bool themeDark;
  final Color heroPrimary;
  final Color heroDeep;
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

  Widget _financeHeroCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => context.go('/financeiro'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: Colors.white,
          foregroundColor: BrandPalette.deep(heroDeep),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
          ),
        ),
        child: const Text('Abrir financeiro'),
      ),
    );
  }

  String _metaLine() {
    final meta = finData?.previsaoReceita ?? 0;
    final ticket = finData?.ticketMedio ?? 0;
    if (meta > 0) {
      return 'Meta R\$ ${meta.toStringAsFixed(0)}';
    }
    // Ticket médio só com receita real — evita R$1100 “fantasma” em mês zerado.
    if (receitaAtual > 0 && ticket > 0) {
      return 'Ticket médio R\$ ${ticket.toStringAsFixed(0)} · defina meta no financeiro';
    }
    return 'Defina a meta mensal no financeiro';
  }

  bool get _showTicketMedio {
    final ticket = finData?.ticketMedio ?? 0;
    return receitaAtual > 0 && ticket > 0;
  }

  Widget _receitaAmount(BuildContext context) {
    if (loadingFin) {
      return Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.30),
        child: Container(
          width: 160,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (reduceMotion) {
      return Text(
        'R\$ ${receitaAtual.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
        style: AppTypography.mono(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1,
        ),
      );
    }
    return AnimatedBuilder(
      animation: counterAnim,
      builder:
          (ctx, _) => Text(
            'R\$ ${counterAnim.value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
            style: AppTypography.mono(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: gradientCtrl,
        builder: (ctx, _) {
          final angle = reduceMotion ? 0.0 : gradientCtrl.value * 2 * math.pi;
          final begin = Alignment(-math.cos(angle), -math.sin(angle));
          final end = Alignment(math.cos(angle), math.sin(angle));
          return Semantics(
            label:
                'Panorama financeiro de $mes. '
                'Recebido R\$ ${receitaAtual.toInt()}. '
                'Toque para abrir financeiro',
            button: true,
            child: InkWell(
              onTap: () => context.go('/financeiro'),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [heroPrimary, heroDeep],
                    begin: begin,
                    end: end,
                  ),
                  boxShadow: [
                    ...TokensStrip.coloredDepthGlow(
                      heroPrimary,
                      strength: themeDark ? 0.14 : 0.18,
                    ),
                    BoxShadow(
                      color: heroPrimary.withValues(
                        alpha: themeDark ? 0.14 : 0.10,
                      ),
                      blurRadius: themeDark ? 16 : 14,
                      offset: const Offset(0, 8),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  _compactZeroRevenue ? 14 : 16,
                ),
                child: CustomPaint(
                  foregroundPainter: DashboardHeroGridPainter(),
                  child:
                      _compactZeroRevenue
                          ? _buildCompactContent(context)
                          : _buildFullContent(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Receita · $mes', style: dashboardHeroEyebrowOnTeal()),
        const SizedBox(height: 6),
        Text(
          'Sem receita em $mes. Abra o financeiro para lançar cobranças.',
          style: dashboardHeroCaptionOnTealStyle(),
        ),
        const SizedBox(height: 14),
        _financeHeroCta(context),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Receita recebida · $mes', style: dashboardHeroEyebrowOnTeal()),
        const SizedBox(height: 4),
        Text(
          metaSuperada
              ? 'Meta superada · receita acima do previsto.'
              : pendente > 0
              ? 'Recebido agora. Faltam R\$ ${pendente.toInt()} para a meta.'
              : 'Recebido agora. Meta do mês sob controle.',
          style: dashboardHeroCaptionOnTealStyle(),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _receitaAmount(context),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 5),
              child: Text(
                'recebido',
                style: dashboardHeroEyebrowOnTeal().copyWith(
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(_metaLine(), style: dashboardHeroMutedOnTealStyle()),
            if (metaSuperada) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  'SUPERADA',
                  style: dashboardHeroEyebrowOnTeal().copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
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
                    style: dashboardHeroCaptionOnTealStyle(),
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
                        style: dashboardHeroCaptionOnTealStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      FxSparkline(
                        data: receitaTrend,
                        color: Colors.white.withValues(alpha: 0.92),
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
        DashboardHeroProgressRail(
          progress: progressRaw.clamp(0.0, 1.0),
          exceeded: metaSuperada,
          glow: BrandPalette.accent(heroPrimary),
          percentLabel: financePercentLabel(
            progressRaw,
            exceeded: metaSuperada,
          ),
          excessBeyondMeta: metaSuperada ? math.max(0, progressRaw - 1) : 0,
        ),
        const SizedBox(height: TokensStrip.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DashboardHeroMiniStat(
              label: 'Pendente',
              value: 'R\$ ${pendente.toInt()}',
            ),
            Container(
              width: 1,
              height: 30,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            DashboardHeroMiniStat(
              label: financeInadimplLabel(MediaQuery.sizeOf(context).width),
              value: '${finData?.totalInadimplentes ?? 0}',
              suffix: ' alunos',
            ),
            if (_showTicketMedio) ...[
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              DashboardHeroMiniStat(
                label: 'Ticket médio',
                value: 'R\$ ${finData!.ticketMedio.toStringAsFixed(0)}',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

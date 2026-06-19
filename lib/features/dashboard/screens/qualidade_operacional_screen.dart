import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class QualidadeOperacionalData {
  final double ticketPessoal;
  final double ticketMercado;
  final int retencaoPessoal;
  final int retencaoMercado;
  final int score;
  final String recomendacao;

  QualidadeOperacionalData({
    required this.ticketPessoal,
    required this.ticketMercado,
    required this.retencaoPessoal,
    required this.retencaoMercado,
    required this.score,
    required this.recomendacao,
  });

  factory QualidadeOperacionalData.fromJson(Map<String, dynamic> j) =>
      QualidadeOperacionalData(
        ticketPessoal: (j['ticketPessoal'] as num).toDouble(),
        ticketMercado: (j['ticketMercado'] as num).toDouble(),
        retencaoPessoal: j['retencaoPessoal'],
        retencaoMercado: j['retencaoMercado'],
        score: j['score'],
        recomendacao: j['recomendacao'],
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final qualidadeProvider = FutureProvider<QualidadeOperacionalData>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/dashboard/qualidade');
  return QualidadeOperacionalData.fromJson(res.data as Map<String, dynamic>);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class QualidadeOperacionalScreen extends ConsumerWidget {
  const QualidadeOperacionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(qualidadeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return fxScreenA11yScope(
      label: 'Qualidade Operacional',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Qualidade Operacional',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: asyncData.when(
          loading: () => const FxLoading(),
          error:
              (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s5),
                  child: Text(
                    friendlyError(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: EagleTokens.bad),
                  ),
                ),
              ),
          data: (data) => _QualidadeBody(data: data, isDark: isDark),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _QualidadeBody extends StatelessWidget {
  final QualidadeOperacionalData data;
  final bool isDark;
  const _QualidadeBody({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.accent(primary);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final lineBg = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final scoreColor =
        data.score >= 80
            ? EagleTokens.good
            : data.score >= 50
            ? EagleTokens.warn
            : EagleTokens.bad;

    final scoreLabel =
        data.score >= 80
            ? 'Excelente'
            : data.score >= 50
            ? 'Bom'
            : 'Atenção';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Score Card (brand gradient) ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: EagleTokens.heroGradientFrom(primary, dark: isDark),
              borderRadius: BorderRadius.circular(EagleTokens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          EagleTokens.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Índice Focux',
                            style: AppTypography.inter(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                Text(
                  '${data.score}',
                  style: AppTypography.mono(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  '/100',
                  style: AppTypography.mono(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // Progress arc
                SizedBox(
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: data.score / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.recomendacao,
                    style: AppTypography.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: TokensStrip.s5),

          // ── Score Breakdown ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        size: 14,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Diagnóstico',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                _ScoreRow(
                  label: 'Precificação',
                  value: _ticketScore(),
                  color: _ticketScoreColor(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _ScoreRow(
                  label: 'Retenção',
                  value: _retencaoScore(),
                  color: _retencaoScoreColor(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _ScoreRow(
                  label: 'Score geral',
                  value: data.score,
                  color: scoreColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: TokensStrip.s4),

          // ── Ticket Médio ──
          _MetricCompareCard(
            icon: Icons.attach_money_rounded,
            title: 'Ticket Médio',
            yourLabel: 'Seu Ticket',
            yourValue: 'R\$ ${data.ticketPessoal.toStringAsFixed(0)}',
            marketLabel: 'Mercado',
            marketValue: 'R\$ ${data.ticketMercado.toStringAsFixed(0)}',
            isAbove: data.ticketPessoal >= data.ticketMercado,
            ratio:
                data.ticketMercado > 0
                    ? data.ticketPessoal /
                        (data.ticketPessoal + data.ticketMercado)
                    : 0.5,
            isDark: isDark,
            lineDivider: lineBg,
            ink: ink,
            mute: mute,
            primary: primary,
            accent: accent,
          ),

          const SizedBox(height: 12),

          // ── Retenção ──
          _MetricCompareCard(
            icon: Icons.favorite_rounded,
            title: 'Saúde da Base',
            yourLabel: 'Sua Retenção',
            yourValue: '${data.retencaoPessoal}%',
            marketLabel: 'Mercado',
            marketValue: '${data.retencaoMercado}%',
            isAbove: data.retencaoPessoal >= data.retencaoMercado,
            ratio: data.retencaoPessoal / 100,
            isDark: isDark,
            lineDivider: lineBg,
            ink: ink,
            mute: mute,
            primary: primary,
            accent: accent,
          ),

          const SizedBox(height: TokensStrip.s4),

          // ── Status Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scoreColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Status: $scoreLabel • Baseado em dados anonimizados da plataforma Focux',
                    style: TextStyle(
                      fontSize: 11,
                      color: mute,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _ticketScore() {
    if (data.ticketMercado <= 0) return 100;
    final ratio = data.ticketPessoal / data.ticketMercado;
    return (ratio * 50).clamp(0, 100).round();
  }

  Color _ticketScoreColor() {
    final s = _ticketScore();
    if (s >= 80) return EagleTokens.good;
    if (s >= 50) return EagleTokens.warn;
    return EagleTokens.bad;
  }

  int _retencaoScore() => data.retencaoPessoal.clamp(0, 100);

  Color _retencaoScoreColor() {
    if (data.retencaoPessoal >= 80) return EagleTokens.good;
    if (data.retencaoPessoal >= 50) return EagleTokens.warn;
    return EagleTokens.bad;
  }
}

// ─── Score Row ────────────────────────────────────────────────────────────────

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isDark;
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: mute,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: color.withValues(alpha: isDark ? 0.10 : 0.08),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── Metric Compare Card ──────────────────────────────────────────────────────

class _MetricCompareCard extends StatelessWidget {
  final IconData icon;
  final String title, yourLabel, yourValue, marketLabel, marketValue;
  final bool isAbove;
  final double ratio;
  final bool isDark;
  final Color lineDivider, ink, mute, primary, accent;

  const _MetricCompareCard({
    required this.icon,
    required this.title,
    required this.yourLabel,
    required this.yourValue,
    required this.marketLabel,
    required this.marketValue,
    required this.isAbove,
    required this.ratio,
    required this.isDark,
    required this.lineDivider,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAbove ? EagleTokens.good : EagleTokens.warn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: (isDark ? accent : primary).withValues(
                    alpha: isDark ? 0.14 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: isDark ? accent : primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAbove
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isAbove ? 'Acima' : 'Abaixo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Comparison bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio * 100).round().clamp(5, 95),
                    child: Container(color: isDark ? accent : primary),
                  ),
                  Expanded(
                    flex: (100 - (ratio * 100).round()).clamp(5, 95),
                    child: Container(color: mute.withValues(alpha: 0.20)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Values row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yourLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      yourValue,
                      style: AppTypography.mono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: lineDivider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marketLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      marketValue,
                      style: AppTypography.mono(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: mute,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class FinanceiroResumoScreen extends ConsumerStatefulWidget {
  const FinanceiroResumoScreen({super.key});

  @override
  ConsumerState<FinanceiroResumoScreen> createState() =>
      _FinanceiroResumoScreenState();
}

class _FinanceiroResumoScreenState
    extends ConsumerState<FinanceiroResumoScreen> {
  late int _ano;
  late int _mes;
  bool _loading = false;
  ResumoMensal? _resumo;
  String? _erro;

  static const _meses = [
    '',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final r = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).resumoMensal(_ano, _mes);
      if (mounted) {
        setState(() {
          _resumo = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _mesAnterior() {
    setState(() {
      if (_mes == 1) {
        _mes = 12;
        _ano--;
      } else {
        _mes--;
      }
    });
    _carregar();
  }

  void _mesProximo() {
    setState(() {
      if (_mes == 12) {
        _mes = 1;
        _ano++;
      } else {
        _mes++;
      }
    });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Column(
        children: [
          // Month/year picker
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: _mesAnterior,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                Text(
                  '${_meses[_mes]} $_ano',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 16),
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: _mesProximo,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? _buildLoading(isDark)
                    : _erro != null
                    ? _buildError(isDark, ink, mute, primary)
                    : _resumo == null
                    ? _buildEmpty(isDark, ink, mute, primary)
                    : _buildContent(isDark, ink, mute, primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: FxLoading(strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildError(bool isDark, Color ink, Color mute, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: EagleTokens.bad,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar resumo',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color ink, Color mute, Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.analytics_rounded, color: primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'Sem dados para exibir',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nenhuma mensalidade neste período.',
            style: TextStyle(color: mute, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color ink, Color mute, Color primary) {
    final r = _resumo!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _DonutChartCard(resumo: r, isDark: isDark),
        const SizedBox(height: 16),
        _MetricRow(
          label: 'Total recebido',
          value: 'R\$ ${r.totalRecebido.toStringAsFixed(0)}',
          icon: Icons.check_circle_rounded,
          color: EagleTokens.good,
          isDark: isDark,
        ),
        _MetricRow(
          label: 'Total previsto',
          value: 'R\$ ${r.totalPrevisto.toStringAsFixed(0)}',
          icon: Icons.trending_up_rounded,
          color: primary,
          isDark: isDark,
        ),
        _MetricRow(
          label: 'Inadimplentes',
          value: '${r.inadimplentes}',
          icon: Icons.warning_amber_rounded,
          color: EagleTokens.bad,
          isDark: isDark,
        ),
        _MetricRow(
          label: 'Ticket médio',
          value: 'R\$ ${r.ticketMedio.toStringAsFixed(0)}',
          icon: Icons.receipt_long_rounded,
          color: primary,
          isDark: isDark,
        ),
        _MetricRow(
          label: 'Acumulado anual',
          value: 'R\$ ${r.acumuladoAnual.toStringAsFixed(0)}',
          icon: Icons.savings_rounded,
          color: EagleTokens.good,
          isDark: isDark,
          isLast: true,
        ),
      ],
    );
  }
}

// ─── Navigational arrow ─────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _NavArrow({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line),
        ),
        child: Icon(icon, size: 20, color: ink),
      ),
    );
  }
}

// ─── Donut chart ─────────────────────────────────────────────────────────

class _DonutChartCard extends StatelessWidget {
  final ResumoMensal resumo;
  final bool isDark;
  const _DonutChartCard({required this.resumo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final double recebido = resumo.totalRecebido;
    final double previsto = resumo.totalPrevisto;
    final double pendente = previsto > recebido ? (previsto - recebido) : 0;

    final bool isEmpty = previsto == 0;
    final double percentRecebido =
        isEmpty ? 0 : (recebido / previsto * 100).clamp(0, 100);

    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: fxListCardDecoration(context, accent: primary, radius: 22),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections:
                        isEmpty
                            ? [
                              PieChartSectionData(
                                value: 1,
                                color: mute.withValues(alpha: 0.2),
                                radius: 20,
                                showTitle: false,
                              ),
                            ]
                            : [
                              PieChartSectionData(
                                value: recebido,
                                color: EagleTokens.good,
                                radius: 24,
                                showTitle: false,
                              ),
                              if (pendente > 0)
                                PieChartSectionData(
                                  value: pendente,
                                  color: EagleTokens.warn.withValues(
                                    alpha: 0.5,
                                  ),
                                  radius: 20,
                                  showTitle: false,
                                ),
                            ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentRecebido.toStringAsFixed(0)}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'RECEBIDO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: mute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(
                  color: EagleTokens.good,
                  label: 'Recebido',
                  mute: mute,
                ),
                const SizedBox(width: 20),
                _LegendDot(
                  color: EagleTokens.warn.withValues(alpha: 0.5),
                  label: 'Pendente',
                  mute: mute,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color mute;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: mute,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Metric row (replaces Card+ListTile) ─────────────────────────────────

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isLast;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: fxListCardDecoration(context, accent: color, radius: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: mute,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

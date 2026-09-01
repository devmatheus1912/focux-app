import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import '../financeiro_hub_scope.dart';
import '../providers/financeiro_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';

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
  DateTime? _fetchedAt;

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
      final now = DateTime.now();
      final isCurrentMonth = _ano == now.year && _mes == now.month;
      final ResumoMensal r;
      if (isCurrentMonth) {
        final home = await ref.read(financeiroHomeProvider.future);
        r = home.resumoMesAtual;
      } else {
        r = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).resumoMensal(_ano, _mes);
      }
      if (mounted) {
        setState(() {
          _resumo = r;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Financeiro métricas. ${freshnessLabel ?? '${_meses[_mes]} $_ano'}',
      child: Column(
        children: [
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
                  style: FocuxHubTypography.sectionTitle(
                    context,
                    color: ink,
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
                    ? const SkeletonList(count: 5)
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: _carregar,
                    )
                    : _resumo == null
                    ? const FxEmptyState(
                      icon: 'coin',
                      title: 'Sem dados para exibir',
                      subtitle: 'Nenhuma mensalidade neste período.',
                    )
                    : _buildContent(isDark, freshnessLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, String? freshnessLabel) {
    final r = _resumo!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        32,
      ),
      children: [
        _DonutChartCard(resumo: r, isDark: isDark),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Do mês',
          caption: freshnessLabel,
          children: [
            FxSettingsTile(
              fxIcon: 'dollar-sign',
              label: 'Total recebido',
              value: formatBrlCurrency(r.totalRecebido, showDecimals: false),
              numeric: true,
              showDivider: true,
              onTap: () => FinanceiroHubScope.maybeOf(context)?.goToMensalidades(),
            ),
            FxSettingsTile(
              fxIcon: 'target',
              label: 'Total previsto',
              value: formatBrlCurrency(r.totalPrevisto, showDecimals: false),
              numeric: true,
              showDivider: true,
              onTap: () => FinanceiroHubScope.maybeOf(context)?.goToMensalidades(),
            ),
            FxSettingsTile(
              fxIcon: 'alert-triangle',
              label: 'Inadimplentes',
              value: '${r.inadimplentes}',
              danger: r.inadimplentes > 0,
              showDivider: true,
              onTap: () => FinanceiroHubScope.maybeOf(context)?.goToMensalidades(),
            ),
            FxSettingsTile(
              fxIcon: 'user',
              label: 'Ticket médio',
              value: formatBrlCurrency(r.ticketMedio, showDecimals: false),
              numeric: true,
              showDivider: true,
              onTap: () => FinanceiroHubScope.maybeOf(context)?.goToMensalidades(),
            ),
            FxSettingsTile(
              fxIcon: 'dollar-sign',
              label: 'Acumulado anual',
              value: formatBrlCurrency(r.acumuladoAnual, showDecimals: false),
              numeric: true,
              showDivider: false,
              onTap: () => FinanceiroHubScope.maybeOf(context)?.goToMensalidades(),
            ),
          ],
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
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
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
                      style: AppTypography.mono(
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
            const SizedBox(height: TokensStrip.s4),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/business_repository.dart';
import '../utils/business_reports_display.dart';
import '../widgets/business_reports_help_sheet.dart';

final _repoProvider = Provider(
  (ref) => BusinessRepository(ref.read(apiClientProvider)),
);

class BusinessReportsScreen extends ConsumerStatefulWidget {
  const BusinessReportsScreen({super.key});

  @override
  ConsumerState<BusinessReportsScreen> createState() =>
      _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends ConsumerState<BusinessReportsScreen> {
  final _openedAt = DateTime.now();
  BusinessSnapshot? _snapshot;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final s = await ref.read(_repoProvider).snapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = s;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.businessReportsViewed,
      props: {'alunos': _snapshot?.alunosAtivos ?? 0},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.businessReportsTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final snap = _snapshot;

    return fxScreenA11yScope(
      label: 'Receita recorrente',
      child: FeatureGate(
        featureName: 'Relatórios de negócio',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'relatorios',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Receita recorrente',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como ler a receita recorrente',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.businessReportsHelpOpened,
                  );
                  showBusinessReportsHelpSheet(context);
                },
              ),
            ],
          ),
          body: _loading
              ? const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              )
              : _erro != null
              ? FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _erro!,
                onRetry: _carregar,
              )
              : RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  AnalyticsService.instance.track(
                    ProductEvents.businessReportsRefreshed,
                  );
                  await _carregar();
                },
                child: snap == null
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: FxEmptyState(
                            icon: 'coin',
                            title: 'Sem dados de receita',
                            subtitle:
                                'Quando houver mensalidades, o MRR e a retenção aparecem aqui.',
                            action: FxEmptyAction(
                              label: 'Tentar de novo',
                              onTap: _carregar,
                            ),
                          ),
                        ),
                      ],
                    )
                    : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        8,
                        FxSettingsLayout.pageInset,
                        110,
                      ),
                      children: [
                        const DashboardSectionHeader(title: 'Mês'),
                        const SizedBox(height: TokensStrip.s3),
                        InkWell(
                          onTap: () => context.push('/financeiro'),
                          borderRadius: BorderRadius.circular(12),
                          child: OperationalMetricTile(
                            label: 'Recebido',
                            value: businessMoneyLabel(snap.mrrAtual),
                            hint:
                                'Previsto ${businessMoneyLabel(snap.mrrPrevisto)}',
                            color: EagleTokens.moneyGreen,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        InkWell(
                          onTap: () => context.push('/financeiro'),
                          borderRadius: BorderRadius.circular(12),
                          child: OperationalMetricTile(
                            label: 'Mês anterior',
                            value: businessMoneyLabel(snap.mrrAnterior),
                            hint: 'Comparar no financeiro',
                            color: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        const DashboardSectionHeader(title: 'Retenção'),
                        const SizedBox(height: TokensStrip.s3),
                        OperationalMetricTile(
                          label: 'NDR',
                          value: '${snap.ndrPct.toStringAsFixed(1)}%',
                          hint: businessNdrStatus(snap.ndrPct),
                          color: businessNdrRuim(snap.ndrPct)
                              ? EagleTokens.bad
                              : EagleTokens.moneyGreen,
                          isDark: isDark,
                          emphasis: businessNdrRuim(snap.ndrPct)
                              ? OperationalMetricEmphasis.alert
                              : OperationalMetricEmphasis.normal,
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        InkWell(
                          onTap: () => context.go('/alunos'),
                          borderRadius: BorderRadius.circular(12),
                          child: OperationalMetricTile(
                            label: 'Alunos ativos',
                            value: businessAlunosLabel(
                              snap.alunosAtivos,
                              snap.alunosTotal,
                            ),
                            hint: 'Abrir a base',
                            color: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        InkWell(
                          onTap: () => context.push('/financeiro'),
                          borderRadius: BorderRadius.circular(12),
                          child: OperationalMetricTile(
                            label: 'Inadimplentes',
                            value: '${snap.inadimplentes}',
                            hint: snap.inadimplentes > 0
                                ? 'Cobre em Mensalidades'
                                : 'Sem inadimplência no recorte',
                            color: snap.inadimplentes > 0
                                ? EagleTokens.bad
                                : EagleTokens.moneyGreen,
                            isDark: isDark,
                            emphasis: snap.inadimplentes > 0
                                ? OperationalMetricEmphasis.alert
                                : OperationalMetricEmphasis.normal,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        const DashboardSectionHeader(title: 'Ticket'),
                        const SizedBox(height: TokensStrip.s3),
                        OperationalMetricTile(
                          label: 'ARPA',
                          value: businessMoneyLabel(snap.arpa),
                          hint:
                              'LTV ${businessMoneyLabel(snap.ltvProxy)}',
                          color: primary,
                          isDark: isDark,
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        const DashboardSectionHeader(
                          title: 'Cobrança e ativação',
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Text(
                          'A recuperação é a mesma do Dunning.',
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxSatelliteListTile(
                          title: 'Recuperação',
                          subtitle: Text(
                            '${snap.dunningRecoveryPct.toStringAsFixed(1)}% · ${businessDunningFalhasLabel(snap.dunningAbertas)}',
                          ),
                          onTap: () => context.push('/dunning'),
                        ),
                        OperationalMetricTile(
                          label: 'Ativação',
                          value: '${snap.pqlScore} pts',
                          hint: businessPqlLabel(snap.pqlClassificacao),
                          color: primary,
                          isDark: isDark,
                        ),
                      ],
                    ),
              ),
        ),
      ),
    );
  }
}

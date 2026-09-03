import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/business_repository.dart';
import '../utils/business_reports_display.dart';

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

  void _abrirFinanceiro() {
    AnalyticsService.instance.track(ProductEvents.financeiroViewed);
    goPersonalShellTab(context, '/financeiro');
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
          constrainWidth: false,
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
                  showFxHelpSheet(
                    context,
                    title: 'Receita recorrente',
                    subtitle:
                        'MRR e retenção da base. Cobrança auto continua em Dunning.',
                    tips: const [
                      FxHelpTip('Como calculamos', businessComoCalculamos),
                      FxHelpTip(
                        'NDR',
                        'Acima de 100% a base cresce em reais.',
                      ),
                      FxHelpTip(
                        'Cobrança',
                        'A recuperação é a mesma do Dunning.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: _loading
              ? const SkeletonList(count: 6)
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
                        const SizedBox(height: 48),
                        FxEmptyState(
                          icon: 'coin',
                          title: 'Sem dados de receita',
                          subtitle:
                              'Quando houver mensalidades, o MRR e a retenção aparecem aqui.',
                          action: FxEmptyAction(
                            label: 'Ver financeiro',
                            onTap: _abrirFinanceiro,
                          ),
                        ),
                      ],
                    )
                    : FxContentWidthLimiter(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(TokensStrip.s4),
                        children: [
                          _BusinessFocusCard(
                            snap: snap,
                            isDark: isDark,
                            onFinanceiro: _abrirFinanceiro,
                          ),
                          const SizedBox(height: TokensStrip.s4),
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
                          OperationalMetricTile(
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
                          const SizedBox(height: TokensStrip.s4),
                          const DashboardSectionHeader(
                            title: 'Cobrança e ativação',
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          FxSatelliteListTile(
                            title: 'Recuperação',
                            subtitle: Text(
                              '${snap.dunningRecoveryPct.toStringAsFixed(1)}% · ${businessDunningFalhasLabel(snap.dunningAbertas)}',
                            ),
                            onTap: () => context.push('/dunning'),
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          const DashboardSectionHeader(title: 'Mais'),
                          const SizedBox(height: TokensStrip.s2),
                          OperationalMetricTile(
                            label: 'ARPA',
                            value: businessMoneyLabel(snap.arpa),
                            hint: 'LTV ${businessMoneyLabel(snap.ltvProxy)}',
                            color: primary,
                            isDark: isDark,
                          ),
                          const SizedBox(height: TokensStrip.s2),
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
      ),
    );
  }
}

class _BusinessFocusCard extends StatelessWidget {
  const _BusinessFocusCard({
    required this.snap,
    required this.isDark,
    required this.onFinanceiro,
  });

  final BusinessSnapshot snap;
  final bool isDark;
  final VoidCallback onFinanceiro;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: 'Recebido ${businessMoneyLabel(snap.mrrAtual)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recebido', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            businessMoneyLabel(snap.mrrAtual),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Previsto ${businessMoneyLabel(snap.mrrPrevisto)}',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: 'Ver financeiro',
              accent: EagleTokens.moneyGreen,
              isDark: isDark,
              onPressed: onFinanceiro,
            ),
          ),
        ],
      ),
    );
  }
}

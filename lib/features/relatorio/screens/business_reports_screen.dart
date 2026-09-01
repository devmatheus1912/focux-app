import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
                        FxSettingsGroup(
                          header: 'Mês',
                          caption: 'O que entrou, o previsto e o mês passado.',
                          children: [
                            FxSettingsTile(
                              fxIcon: 'coin',
                              label: 'Recebido',
                              value: businessMoneyLabel(snap.mrrAtual),
                              numeric: true,
                              onTap: () => context.push('/financeiro'),
                            ),
                            FxSettingsTile(
                              fxIcon: 'target',
                              label: 'Previsto',
                              value: businessMoneyLabel(snap.mrrPrevisto),
                              numeric: true,
                              onTap: () => context.push('/financeiro'),
                            ),
                            FxSettingsTile(
                              fxIcon: 'trend',
                              label: 'Mês anterior',
                              value: businessMoneyLabel(snap.mrrAnterior),
                              numeric: true,
                              showDivider: false,
                              onTap: () => context.push('/financeiro'),
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Retenção',
                          caption: 'NDR acima de 100% é expansão em reais.',
                          children: [
                            FxSettingsTile(
                              fxIcon: 'trend',
                              label: 'NDR',
                              value: '${snap.ndrPct.toStringAsFixed(1)}%',
                              subtitle: businessNdrStatus(snap.ndrPct),
                              numeric: true,
                              danger: businessNdrRuim(snap.ndrPct),
                              highlight: !businessNdrRuim(snap.ndrPct),
                              onTap: () {},
                            ),
                            FxSettingsTile(
                              fxIcon: 'users',
                              label: 'Alunos ativos',
                              value: businessAlunosLabel(
                                snap.alunosAtivos,
                                snap.alunosTotal,
                              ),
                              numeric: true,
                              onTap: () => context.go('/alunos'),
                            ),
                            FxSettingsTile(
                              fxIcon: 'alert-triangle',
                              label: 'Inadimplentes',
                              value: '${snap.inadimplentes}',
                              numeric: true,
                              danger: snap.inadimplentes > 0,
                              showDivider: false,
                              onTap: () => context.push('/financeiro'),
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Ticket',
                          children: [
                            FxSettingsTile(
                              fxIcon: 'coin',
                              label: 'ARPA',
                              value: businessMoneyLabel(snap.arpa),
                              numeric: true,
                              onTap: () {},
                            ),
                            FxSettingsTile(
                              fxIcon: 'trend',
                              label: 'LTV (proxy)',
                              value: businessMoneyLabel(snap.ltvProxy),
                              numeric: true,
                              showDivider: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Cobrança e ativação',
                          caption: 'A recuperação é a mesma do Dunning.',
                          children: [
                            FxSettingsTile(
                              fxIcon: 'alert-triangle',
                              label: 'Recuperação',
                              value:
                                  '${snap.dunningRecoveryPct.toStringAsFixed(1)}%',
                              subtitle: businessDunningFalhasLabel(
                                snap.dunningAbertas,
                              ),
                              numeric: true,
                              onTap: () => context.push('/dunning'),
                            ),
                            FxSettingsTile(
                              fxIcon: 'spark',
                              label: 'Ativação',
                              value: '${snap.pqlScore} pts',
                              subtitle: businessPqlLabel(
                                snap.pqlClassificacao,
                              ),
                              showDivider: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
        ),
      ),
    );
  }
}

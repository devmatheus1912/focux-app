import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
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
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';
import '../widgets/dunning_ops_help_sheet.dart';

final _repoProvider = Provider(
  (ref) => DunningRepository(ref.read(apiClientProvider)),
);

class DunningOpsScreen extends ConsumerStatefulWidget {
  const DunningOpsScreen({super.key});

  @override
  ConsumerState<DunningOpsScreen> createState() => _DunningOpsScreenState();
}

class _DunningOpsScreenState extends ConsumerState<DunningOpsScreen> {
  final _openedAt = DateTime.now();
  DunningSnapshot? _snapshot;
  List<DunningFalha> _falhas = [];
  var _loading = true;
  String? _erro;
  int? _marcandoId;
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
      final home = await ref.read(_repoProvider).getHome();
      if (!mounted) return;
      setState(() {
        _snapshot = home.snapshot;
        _falhas = home.falhas;
        _fetchedAt = DateTime.now();
        _loading = false;
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
      ProductEvents.dunningHubViewed,
      props: {'abertas': _snapshot?.abertas ?? 0},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.dunningHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
      );
    }
  }

  Future<void> _marcarRecuperado(DunningFalha falha) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar como recuperada?',
      subtitle: dunningContextoLabel(falha.contexto),
      message:
          'A falha some da lista. Use só se o pagamento já entrou.',
      confirmLabel: 'Marcar recuperada',
    );
    if (!ok || !mounted) return;

    AnalyticsService.instance.track(
      ProductEvents.dunningMarkedRecovered,
      props: {
        'feature': 'dunning',
        'falha_id': falha.id,
        if (falha.alunoId != null) 'aluno_id': falha.alunoId,
      },
    );
    setState(() => _marcandoId = falha.id);
    try {
      await ref.read(_repoProvider).marcarRecuperado(falha.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Falha marcada como recuperada.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _marcandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final snap = _snapshot;

    return fxScreenA11yScope(
      label: 'Cobrança auto',
      child: FeatureGate(
        featureName: 'Cobrança automática',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'financeiro',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Cobrança auto',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar a cobrança automática',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.dunningHubHelpOpened,
                  );
                  showDunningOpsHelpSheet(context);
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
                    ProductEvents.dunningHubRefreshed,
                  );
                  await _carregar();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    110,
                  ),
                  children: [
                    if (snap != null)
                      FxSettingsGroup(
                        header: 'Recuperação',
                        caption: 'A taxa é a mesma da Receita recorrente.',
                        children: [
                          FxSettingsTile(
                            fxIcon: 'trend',
                            label: 'Taxa',
                            value: dunningRateLabel(snap.recoveryRate),
                            numeric: true,
                            highlight: !dunningTaxaFraca(
                              snap.recoveryRate,
                              snap.total,
                            ),
                            danger: dunningTaxaFraca(
                              snap.recoveryRate,
                              snap.total,
                            ),
                            onTap: () {},
                          ),
                          FxSettingsTile(
                            fxIcon: 'alert-triangle',
                            label: 'Em aberto',
                            value: '${snap.abertas}',
                            numeric: true,
                            danger: snap.abertas > 0,
                            onTap: () {},
                          ),
                          FxSettingsTile(
                            fxIcon: 'circle-check',
                            label: 'Recuperadas',
                            value: dunningRecuperadasLabel(
                              snap.recuperadas,
                              snap.total,
                            ),
                            numeric: true,
                            showDivider: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    if (_falhas.isEmpty)
                      SizedBox(
                        height: 280,
                        child: FxEmptyState(
                          icon: 'circle-check',
                          title: 'Tudo em dia',
                          subtitle:
                              'Nenhuma falha de pagamento em aberto.',
                          action: FxEmptyAction(
                            label: 'Atualizar',
                            onTap: _carregar,
                          ),
                        ),
                      )
                    else
                      FxSettingsGroup(
                        header: 'Em aberto',
                        caption: 'Toque para marcar como recuperada.',
                        children: [
                          for (var i = 0; i < _falhas.length; i++)
                            FxSettingsTile(
                              fxIcon: 'alert-triangle',
                              label: dunningContextoLabel(_falhas[i].contexto),
                              value: _marcandoId == _falhas[i].id
                                  ? '…'
                                  : dunningMoneyLabel(_falhas[i].valor),
                              subtitle: dunningFalhaSubtitle(
                                _falhas[i].motivo,
                                _falhas[i].tentativa,
                              ),
                              numeric: true,
                              danger: true,
                              showDivider: i != _falhas.length - 1,
                              onTap: _marcandoId == _falhas[i].id
                                  ? () {}
                                  : () => _marcarRecuperado(_falhas[i]),
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

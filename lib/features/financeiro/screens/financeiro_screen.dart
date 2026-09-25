import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../financeiro_hub_scope.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';
import '../widgets/financeiro_help_sheet.dart';
import 'financeiro_dashboard_screen.dart';
import 'financeiro_mensalidades_tab.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key, this.initialAlunoId});

  final int? initialAlunoId;

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> {
  /// P0 do domínio = lista (A30). Panorama (mês + KPIs) atrás de Mais.
  FinanceiroHubView _view = FinanceiroHubView.mensalidades;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;

  /// Incrementa para pedir abertura do form na aba Mensalidades.
  int _novaMensalidadeToken = 0;

  Future<void> _abrirMaisVistas() async {
    final picked = await showFxInsetPickerSheet<FinanceiroHubView>(
      context,
      title: 'Mais no financeiro',
      selected: _view,
      items: [
        FxInsetPickerSheetItem(
          value: FinanceiroHubView.mensalidades,
          label: financeiroHubViewLabel(FinanceiroHubView.mensalidades),
        ),
        for (final v in financeiroHubSecondaryViews)
          FxInsetPickerSheetItem(
            value: v,
            label: financeiroHubViewLabel(v),
          ),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    if (picked == FinanceiroHubView.mensalidades) {
      AnalyticsService.instance.track(
        ProductEvents.financeiroMensalidadesOpened,
        props: {'source': 'picker'},
      );
    }
    setState(() => _view = picked);
  }

  void _irParaMensalidades({String source = 'hub'}) {
    AnalyticsService.instance.track(
      ProductEvents.financeiroMensalidadesOpened,
      props: {'source': source},
    );
    setState(() => _view = FinanceiroHubView.mensalidades);
  }

  void _abrirNovaMensalidade({String source = 'hub'}) {
    AnalyticsService.instance.track(
      ProductEvents.financeiroMensalidadesOpened,
      props: {'source': source},
    );
    // Prefetch in parallel so the sheet opens with alunos ready.
    unawaited(
      Future(() async {
        try {
          await ref.read(alunosProvider.future);
        } catch (_) {}
      }),
    );
    setState(() {
      _view = FinanceiroHubView.mensalidades;
      _novaMensalidadeToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(planoFeaturesProvider);
    final features = featuresAsync.value;
    final hasFinanceiro = features?.financeiro == true;

    if (features == null || !hasFinanceiro) {
      return const FeatureGate(
        featureName: 'Financeiro',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'financeiro',
        child: SizedBox.shrink(),
      );
    }

    final homeAsync = ref.watch(financeiroHomeProvider);
    final home = homeAsync.value;
    final planoFromHome = home?.planoFeatures;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    if (home != null && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        AnalyticsService.instance.track(
          ProductEvents.financeiroViewed,
          props: {
            if (widget.initialAlunoId != null) 'alunoId': widget.initialAlunoId,
          },
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.financeiroTtv,
            props: {'ms': DateTime.now().difference(_openedAt).inMilliseconds},
          );
        }
      });
    }

    return FeatureGate(
      featureName: 'Financeiro',
      requiredPlan: SubscriptionPlan.PRO,
      capability: 'financeiro',
      child: _buildContent(context, home?.fetchedAt),
    );
  }

  Widget _buildContent(BuildContext context, DateTime? fetchedAt) {
    return fxScreenA11yScope(
      label: 'Financeiro',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Financeiro',
          subtitle: financeiroHubSubtitle(
            view: _view,
            freshness: FxHubFreshness.fromFetchedAt(fetchedAt),
          ),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            ShellHeaderIconButton(
              icon: 'route',
              tooltip: 'Mais no financeiro',
              onTap: _abrirMaisVistas,
            ),
            SizedBox(width: FxHelpChrome.gap),
            FxHelpIconButton(
              tooltip: 'Como usar o financeiro',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.financeiroHelpOpened,
                );
                showFinanceiroHelpSheet(context);
              },
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: FinanceiroHubScope(
            goToMensalidades: _irParaMensalidades,
            openNovaMensalidade: _abrirNovaMensalidade,
            child: Column(
              children: [
                if (widget.initialAlunoId != null)
                  _FinanceiroAlunoContextBanner(
                    alunoId: widget.initialAlunoId!,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _view.index,
                    children: [
                      FinanceiroMensalidadesTab(
                        initialAlunoId: widget.initialAlunoId,
                        novaMensalidadeToken: _novaMensalidadeToken,
                      ),
                      const FinanceiroDashboardScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceiroAlunoContextBanner extends ConsumerWidget {
  const _FinanceiroAlunoContextBanner({required this.alunoId});

  final int alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final nome = alunoAsync.value?.nome;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Text(
        financeiroAlunoContextLabel(nome),
        style: FxSettingsLayout.sectionHeader(
          color: ShellChrome.of(context).mute,
        ),
      ),
    );
  }
}

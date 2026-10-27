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
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../recorrencia/screens/recorrencia_screen.dart';
import '../data/financeiro_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../financeiro_hub_scope.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';
import '../widgets/financeiro_linhas_estado.dart';
import '../widgets/financeiro_numeros_mes.dart';
import '../widgets/financeiro_help_sheet.dart';
import 'financeiro_resultados_screen.dart';
import 'financeiro_mensalidades_tab.dart';

part 'financeiro_screen_widgets.part.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({
    super.key,
    this.initialAlunoId,
    this.initialSegmento = FinanceiroSegmento.mensalidades,
  });

  final int? initialAlunoId;
  final FinanceiroSegmento initialSegmento;

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> {
  late FinanceiroSegmento _segmento = widget.initialSegmento;

  /// Segmentos já abertos: só carregam na primeira visita e depois ficam vivos.
  late final Set<FinanceiroSegmento> _visitados = {widget.initialSegmento};
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;

  /// Incrementa para pedir abertura do form na aba Mensalidades.
  int _novaMensalidadeToken = 0;

  /// Filtro pedido pelos números do mês (valem quando o token muda).
  MensalidadeFiltro? _filtroPedido;
  int _filtroToken = 0;

  void _trocarSegmento(FinanceiroSegmento segmento) {
    if (segmento == _segmento) return;
    setState(() {
      _segmento = segmento;
      _visitados.add(segmento);
    });
  }

  void _irParaMensalidades({String source = 'hub'}) {
    AnalyticsService.instance.track(
      ProductEvents.financeiroMensalidadesOpened,
      props: {'source': source},
    );
    _trocarSegmento(FinanceiroSegmento.mensalidades);
  }

  void _abrirFiltro(MensalidadeFiltro filtro) {
    AnalyticsService.instance.track(
      ProductEvents.financeiroMensalidadesOpened,
      props: {'source': 'numeros_mes'},
    );
    setState(() {
      _segmento = FinanceiroSegmento.mensalidades;
      _filtroPedido = filtro;
      _filtroToken++;
    });
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
      _segmento = FinanceiroSegmento.mensalidades;
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
            freshness: FxHubFreshness.fromFetchedAt(fetchedAt),
          ),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
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
            openFiltro: _abrirFiltro,
            child: Column(
              children: [
                if (widget.initialAlunoId != null)
                  _FinanceiroAlunoContextBanner(alunoId: widget.initialAlunoId!)
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FxChoiceStrip<FinanceiroSegmento>(
                        itens: [
                          for (final seg in FinanceiroSegmento.values)
                            FxChoiceItem(
                              value: seg,
                              label: financeiroSegmentoLabel(
                                seg,
                                S.of(context),
                              ),
                            ),
                        ],
                        selecionado: _segmento,
                        onSelecionar: _trocarSegmento,
                      ),
                    ),
                  ),
                if (_segmento == FinanceiroSegmento.mensalidades &&
                    widget.initialAlunoId == null)
                  _NumerosDoMes(onAbrir: _abrirFiltro),
                Expanded(
                  child: IndexedStack(
                    index: _segmento.index,
                    children: [
                      FinanceiroMensalidadesTab(
                        initialAlunoId: widget.initialAlunoId,
                        novaMensalidadeToken: _novaMensalidadeToken,
                        filtroPedido: _filtroPedido,
                        filtroToken: _filtroToken,
                      ),
                      _visitados.contains(FinanceiroSegmento.recorrencias)
                          ? const RecorrenciaScreen(embedded: true)
                          : const SizedBox.shrink(),
                      _visitados.contains(FinanceiroSegmento.resultados)
                          ? const FinanceiroResultadosScreen()
                          : const SizedBox.shrink(),
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

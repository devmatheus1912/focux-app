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
import '../data/relatorio_repository.dart';
import '../utils/relatorio_global_display.dart';
import '../widgets/relatorio_ranking_catalog_sheet.dart';
import '../widgets/relatorio_ranking_tile.dart';

class RelatorioGlobalScreen extends ConsumerStatefulWidget {
  const RelatorioGlobalScreen({super.key});

  @override
  ConsumerState<RelatorioGlobalScreen> createState() =>
      _RelatorioGlobalScreenState();
}

class _RelatorioGlobalScreenState extends ConsumerState<RelatorioGlobalScreen> {
  final _openedAt = DateTime.now();
  ResumoGlobal? _dados;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final dados = await RelatorioRepository(
        ref.read(apiClientProvider),
      ).resumoGlobal();
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    final dados = _dados;
    AnalyticsService.instance.track(
      ProductEvents.relatoriosHubViewed,
      props: {
        'alunos': dados?.totalAlunos ?? 0,
        'media': dados?.aderenciaMediaGeral ?? 0,
      },
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.relatoriosHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
          'alunos': dados?.totalAlunos ?? 0,
        },
      );
    }
  }

  void _abrirAlunos() {
    AnalyticsService.instance.track(ProductEvents.alunosViewed);
    goPersonalShellTab(context, '/alunos');
  }

  void _abrirRelatorioAluno(ResumoAluno aluno) {
    context.push(
      '/alunos/${aluno.alunoId}/relatorio',
      extra: aluno.alunoNome,
    );
  }

  void _abrirRanking({
    required String title,
    required List<ResumoAluno> alunos,
    required bool attention,
  }) {
    showRelatorioRankingCatalogSheet(
      context,
      title: title,
      alunos: alunos,
      attention: attention,
      onAluno: _abrirRelatorioAluno,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final dados = _dados;
    final catalogoMais =
        dados == null ? const <ResumoAluno>[] : relatorioCatalogoMais(dados);
    final catalogoMenos =
        dados == null ? const <ResumoAluno>[] : relatorioCatalogoMenos(dados);
    final firstAtencao = firstRelatorioAtencao(catalogoMenos);

    return fxScreenA11yScope(
      label: 'Relatórios',
      child: FeatureGate(
        featureName: 'Relatórios',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'relatorios',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Relatórios',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como ler os relatórios',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.relatoriosHubHelpOpened,
                  );
                  showFxHelpSheet(
                    context,
                    title: 'Relatórios',
                    subtitle: 'Panorama da base. O PDF de um aluno continua no 360.',
                    tips: const [
                      FxHelpTip('Como calculamos', relatorioComoCalculamos),
                      FxHelpTip(
                        'Rankings',
                        'O fold mostra 3. Ver mais abre a base ordenada. Toque no aluno para o relatório dele.',
                      ),
                      FxHelpTip(
                        'Atenção',
                        'Quem está embaixo não é alerta. Para esfriamento, use Alertas.',
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
                onRetry: _load,
              )
              : RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  AnalyticsService.instance.track(
                    ProductEvents.relatoriosHubRefreshed,
                  );
                  await _load();
                },
                child: dados == null || dados.totalAlunos == 0
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        FxEmptyState(
                          icon: 'users',
                          title: 'Nenhum aluno na base',
                          subtitle:
                              'Quando houver alunos, a média de aderência e os rankings aparecem aqui.',
                          action: FxEmptyAction(
                            label: 'Ver alunos',
                            onTap: _abrirAlunos,
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
                          _RelatorioFocusCard(
                            dados: dados,
                            firstAtencao: firstAtencao,
                            isDark: isDark,
                            onAlunos: _abrirAlunos,
                            onAluno: _abrirRelatorioAluno,
                            onRetencao: () => context.push('/retencao'),
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          OperationalMetricTile(
                            label: 'Alunos',
                            value: '${dados.totalAlunos}',
                            hint: 'Base no recorte',
                            color: primary,
                            isDark: isDark,
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          DashboardSectionHeader(
                            title: 'Mais comprometidos',
                            actionLabel:
                                catalogoMais.length > 3 ? 'Ver mais' : null,
                            onAction:
                                catalogoMais.length > 3
                                    ? () => _abrirRanking(
                                      title: 'Mais comprometidos',
                                      alunos: catalogoMais,
                                      attention: false,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          ..._rankingTiles(
                            relatorioRankingPreview(dados.maisComprometidos),
                            emptyLabel: 'Ainda não há treinos concluídos',
                            attention: false,
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          DashboardSectionHeader(
                            title: 'Precisam de atenção',
                            actionLabel:
                                catalogoMenos.length > 3 ? 'Ver mais' : null,
                            onAction:
                                catalogoMenos.length > 3
                                    ? () => _abrirRanking(
                                      title: 'Precisam de atenção',
                                      alunos: catalogoMenos,
                                      attention: true,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          ..._rankingTiles(
                            relatorioRankingPreview(dados.menosComprometidos),
                            emptyLabel: 'Ninguém precisa de atenção extra',
                            attention: true,
                          ),
                        ],
                      ),
                    ),
              ),
        ),
      ),
    );
  }

  List<Widget> _rankingTiles(
    List<ResumoAluno> alunos, {
    required String emptyLabel,
    required bool attention,
  }) {
    if (alunos.isEmpty) {
      return [
        FxSatelliteListTile(title: emptyLabel),
      ];
    }
    return [
      for (var i = 0; i < alunos.length; i++)
        RelatorioRankingTile(
          aluno: alunos[i],
          attention: attention,
          accentFirst: !attention && i == 0,
          onTap: () => _abrirRelatorioAluno(alunos[i]),
        ),
    ];
  }
}

class _RelatorioFocusCard extends StatelessWidget {
  const _RelatorioFocusCard({
    required this.dados,
    required this.firstAtencao,
    required this.isDark,
    required this.onAlunos,
    required this.onAluno,
    required this.onRetencao,
  });

  final ResumoGlobal dados;
  final ResumoAluno? firstAtencao;
  final bool isDark;
  final VoidCallback onAlunos;
  final void Function(ResumoAluno aluno) onAluno;
  final VoidCallback onRetencao;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    return FxStripCard(
      emphasize: true,
      semanticsLabel:
          'Aderência média ${relatorioAderenciaMediaLabel(dados.aderenciaMediaGeral)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aderência média', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            relatorioAderenciaMediaLabel(dados.aderenciaMediaGeral),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            firstAtencao == null
                ? '${dados.totalAlunos} alunos na base'
                : '${firstAtencao!.alunoNome} pede atenção',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: firstAtencao == null ? 'Ver alunos' : 'Ver aluno',
                accent: firstAtencao == null
                    ? Theme.of(context).colorScheme.primary
                    : EagleTokens.bad,
                isDark: isDark,
                onPressed: () {
                  final alvo = firstAtencao;
                  if (alvo == null) {
                    onAlunos();
                    return;
                  }
                  onAluno(alvo);
                },
              ),
              if (firstAtencao != null)
                DashboardHomeActionChip(
                  label: 'Ver retenção',
                  accent: Theme.of(context).colorScheme.primary,
                  isDark: isDark,
                  onPressed: onRetencao,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

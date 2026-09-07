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
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/nps_repository.dart';
import '../utils/nps_display.dart';
import '../widgets/nps_catalog_sheet.dart';

class NpsDashboardScreen extends ConsumerStatefulWidget {
  const NpsDashboardScreen({super.key});

  @override
  ConsumerState<NpsDashboardScreen> createState() => _NpsDashboardScreenState();
}

class _NpsDashboardScreenState extends ConsumerState<NpsDashboardScreen> {
  NpsResumo? _resumo;
  List<NpsItem> _recentes = [];
  NpsHomeBundle? _bundle;
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  String? _filtroOverride;

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
      final repo = NpsRepository(ref.read(apiClientProvider));
      final home = await repo.getHome();
      if (mounted) {
        setState(() {
          _bundle = home;
          _resumo = home.resumo;
          _recentes = home.recentes;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  String _filtroOf(BuildContext context) =>
      _filtroOverride ??
      npsNormalizeFiltro(
        GoRouterState.of(context).uri.queryParameters['filtro'],
      );

  void _setFiltro(String next) {
    setState(() => _filtroOverride = npsNormalizeFiltro(next));
  }

  void _contatarDetrator(NpsItem item) {
    final alunoId = item.alunoId;
    if (alunoId == null) return;
    AnalyticsService.instance.track(
      ProductEvents.chatThreadOpened,
      props: {'alunoId': alunoId},
    );
    final nome = item.alunoNome;
    if (nome != null && nome.isNotEmpty) {
      context.push('/alunos/$alunoId/chat', extra: nome);
    } else {
      context.push('/alunos/$alunoId');
    }
  }

  void _abrirResposta(NpsItem item) {
    if (!npsHasAluno(item)) return;
    if (npsIsDetrator(item.score)) {
      _contatarDetrator(item);
      return;
    }
    AnalyticsService.instance.track(ProductEvents.alunosViewed);
    context.push('/alunos/${item.alunoId}', extra: item.alunoNome);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final resumo = _resumo;
    final empty = resumo == null || resumo.total == 0;
    final filtro = _filtroOf(context);
    final recentes = npsItemsForFiltro(_recentes, filtro);
    final firstDetrator = firstNpsDetrator(_recentes);

    return fxScreenA11yScope(
      label: 'NPS',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'NPS',
          subtitle: freshnessLabel,
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o NPS',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'NPS',
                    subtitle: 'Satisfação da base e o próximo contato.',
                    tips: const [
                      FxHelpTip('Como calculamos', npsComoCalculamos),
                      FxHelpTip('Score', 'O card do topo é o NPS da operação.'),
                      FxHelpTip(
                        'Detrator',
                        'Nota 6 ou menos pede contato no mesmo dia. O chip Detratores recorta a lista.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body:
            _loading
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
                  onRefresh: _load,
                  child:
                      empty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'star',
                                title: 'Nenhuma resposta ainda',
                                subtitle:
                                    'Assim que seus alunos responderem à pesquisa, o feedback aparece aqui.',
                                action: FxEmptyAction(
                                  label: 'Ver alunos',
                                  onTap: () {
                                    AnalyticsService.instance.track(
                                      ProductEvents.alunosViewed,
                                    );
                                    goPersonalShellTab(context, '/alunos');
                                  },
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
                                _NpsFocusCard(
                                  resumo: resumo,
                                  firstDetrator: firstDetrator,
                                  isDark: isDark,
                                  onContatar: _contatarDetrator,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                OperationalMetricTile(
                                  label: 'Detratores',
                                  value: '${resumo.detratores}',
                                  hint: '${resumo.promotores} promotores',
                                  color: EagleTokens.bad,
                                  isDark: isDark,
                                  emphasis:
                                      resumo.detratores > 0
                                          ? OperationalMetricEmphasis.alert
                                          : OperationalMetricEmphasis.normal,
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                OperationalMetricTile(
                                  label: 'Média',
                                  value: resumo.media.toStringAsFixed(1),
                                  hint: '${resumo.total} respostas',
                                  color: primary,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                DashboardSectionHeader(
                                  title: 'Feedback recente',
                                  actionLabel:
                                      (_bundle?.hasNext ?? false) ||
                                              (_bundle?.totalItens ??
                                                      recentes.length) >
                                                  3
                                          ? 'Ver todos'
                                          : null,
                                  onAction:
                                      (_bundle?.hasNext ?? false) ||
                                              (_bundle?.totalItens ??
                                                      recentes.length) >
                                                  3
                                          ? () {
                                            final bundle = _bundle;
                                            if (bundle == null) return;
                                            showNpsCatalogSheet(
                                              context,
                                              firstPage: bundle,
                                              repo: NpsRepository(
                                                ref.read(apiClientProvider),
                                              ),
                                              filtro: filtro,
                                              onContatar: _abrirResposta,
                                            );
                                          }
                                          : null,
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                Wrap(
                                  spacing: TokensStrip.s2,
                                  runSpacing: TokensStrip.s2,
                                  children: [
                                    FxToggleChip(
                                      label: 'Todos',
                                      selected: filtro.isEmpty,
                                      isDark: isDark,
                                      onTap: () => _setFiltro(''),
                                    ),
                                    FxToggleChip(
                                      label: 'Detratores',
                                      selected:
                                          filtro == npsFiltroDetratores,
                                      isDark: isDark,
                                      onTap:
                                          () => _setFiltro(
                                            npsFiltroDetratores,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                if (npsRecentPreview(recentes).isEmpty)
                                  FxEmptyState(
                                    icon: 'star',
                                    title:
                                        filtro == npsFiltroDetratores
                                            ? 'Nenhum detrator neste recorte'
                                            : 'Nenhum feedback recente',
                                    subtitle:
                                        filtro == npsFiltroDetratores
                                            ? 'As notas baixas que pedem contato aparecem aqui.'
                                            : 'As respostas novas entram nesta lista.',
                                  )
                                else
                                  for (final item
                                      in npsRecentPreview(recentes))
                                    _NpsTile(
                                      item: item,
                                      onContatar:
                                          npsHasAluno(item)
                                              ? () => _abrirResposta(item)
                                              : null,
                                    ),
                              ],
                            ),
                          ),
                ),
      ),
    );
  }
}

class _NpsFocusCard extends StatelessWidget {
  const _NpsFocusCard({
    required this.resumo,
    required this.firstDetrator,
    required this.isDark,
    required this.onContatar,
  });

  final NpsResumo resumo;
  final NpsItem? firstDetrator;
  final bool isDark;
  final void Function(NpsItem item) onContatar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: 'NPS ${resumo.npsScore.toStringAsFixed(1)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NPS', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            resumo.npsScore.toStringAsFixed(1),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resumo.detratores == 0
                ? 'Sem detrator no recorte'
                : '${resumo.detratores} ${resumo.detratores == 1 ? 'detrator' : 'detratores'} para contato',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label:
                  firstDetrator == null
                      ? 'Ver alunos'
                      : 'Contatar detrator',
              accent:
                  firstDetrator == null
                      ? Theme.of(context).colorScheme.primary
                      : EagleTokens.bad,
              isDark: isDark,
              onPressed: () {
                final alvo = firstDetrator;
                if (alvo == null) {
                  AnalyticsService.instance.track(ProductEvents.alunosViewed);
                  goPersonalShellTab(context, '/alunos');
                  return;
                }
                onContatar(alvo);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NpsTile extends StatelessWidget {
  const _NpsTile({required this.item, this.onContatar});

  final NpsItem item;
  final VoidCallback? onContatar;

  @override
  Widget build(BuildContext context) {
    final detrator = npsIsDetrator(item.score);
    return FxSatelliteListTile(
      title:
          item.comentario?.trim().isNotEmpty == true
              ? item.comentario!.trim()
              : (item.alunoNome ?? 'Sem comentário'),
      titleCase: false,
      subtitle: Text('${npsClassify(item.score)} · ${item.criadoEm}'),
      accent: detrator ? EagleTokens.bad : null,
      trailing: Text(
        '${item.score}',
        style: FocuxHubTypography.bodyMuted(
          color: fxScreenMute(context),
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onContatar,
    );
  }
}

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
import '../../../core/widgets/fx_anel.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/nps_repository.dart';
import '../utils/nps_display.dart';
import '../widgets/nps_catalog_sheet.dart';
import '../../../core/theme/fx_icons.dart';

import '../../../core/router/estado_da_rota.dart';

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
      npsNormalizeFiltro(uriDaRota(context).queryParameters['filtro']);

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
          subtitle:
              resumo == null || resumo.total == 0
                  ? freshnessLabel
                  : FxHubFreshness.joinCount(
                    npsRespostasLabel(resumo.total),
                    freshnessLabel,
                  ),
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
                                icon: FxIcons.estrela,
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
                                _NpsDistribuicao(resumo: resumo),
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
                                if (npsMostraFiltros(resumo.total)) ...[
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
                                        selected: filtro == npsFiltroDetratores,
                                        isDark: isDark,
                                        onTap:
                                            () =>
                                                _setFiltro(npsFiltroDetratores),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: TokensStrip.s2),
                                if (npsRecentPreview(recentes).isEmpty)
                                  FxEmptyState(
                                    icon: FxIcons.estrela,
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
                                  for (final item in npsRecentPreview(recentes))
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

/// Topo com a cor da marca, no desenho da Qualidade: anel e textos. Abaixo
/// de [npsRespostasMinimas] o anel mostra quanto falta, não um NPS que oscila.
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
    final sobre = fxPaletaSobreMarca(context);
    final pequena = npsBasePequena(resumo.total);
    final score = npsScoreTexto(resumo.npsScore);
    final alvo = firstDetrator;
    return FxStripCard(
      marca: true,
      semanticsLabel:
          pequena
              ? '${resumo.total} de $npsRespostasMinimas respostas para o NPS aparecer'
              : 'NPS $score. ${npsTituloTopo(resumo.detratores)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FxAnel(
                // −100…100 vira 0…1 no arco.
                fracao:
                    pequena
                        ? resumo.total / npsRespostasMinimas
                        : (resumo.npsScore + 100) / 200,
                cor: sobre.ink,
                fundo: sobre.ink.withValues(alpha: 0.2),
                child: Text(
                  pequena ? '${resumo.total} de $npsRespostasMinimas' : score,
                  textAlign: TextAlign.center,
                  style:
                      pequena
                          ? FocuxHubTypography.cardTitle(color: sobre.ink)
                          : FocuxHubTypography.metric(
                            color: sobre.ink,
                            fontSize: TokensStrip.fontTitulo,
                          ),
                ),
              ),
              const SizedBox(width: TokensStrip.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NPS',
                      style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pequena
                          ? 'O NPS aparece com $npsRespostasMinimas respostas'
                          : npsTituloTopo(resumo.detratores),
                      style: FocuxHubTypography.cardTitle(color: sobre.ink),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      pequena ? npsFaltamTexto(resumo.total) : npsDesdeOInicio,
                      style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Sem detrator, nenhum botão: "Ver alunos" não tinha a ver com o NPS.
          if (alvo != null) ...[
            const SizedBox(height: TokensStrip.s3),
            FxActionChip(
              label: 'Contatar detrator',
              accent: EagleTokens.bad,
              isDark: isDark,
              onPressed: () => onContatar(alvo),
            ),
          ],
        ],
      ),
    );
  }
}

/// Como os alunos avaliam: barra em três partes e as contagens.
class _NpsDistribuicao extends StatelessWidget {
  const _NpsDistribuicao({required this.resumo});

  final NpsResumo resumo;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final partes = [
      (NpsClasse.promotor, 'Promotores (9–10)', resumo.promotores, primary),
      (NpsClasse.neutro, 'Neutros (7–8)', resumo.neutros, chrome.mute),
      (
        NpsClasse.detrator,
        'Detratores (0–6)',
        resumo.detratores,
        EagleTokens.bad,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Como os alunos avaliam',
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.rPill),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final (_, _, n, cor) in partes)
                    if (n > 0) Expanded(flex: n, child: ColoredBox(color: cor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (final (classe, rotulo, n, cor) in partes)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s1),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: Text(
                      '$rotulo · $n',
                      style: FocuxHubTypography.body(
                        color:
                            classe == NpsClasse.detrator && n > 0
                                ? EagleTokens.bad
                                : chrome.ink,
                      ).copyWith(
                        fontWeight:
                            classe == NpsClasse.detrator && n > 0
                                ? FontWeight.w700
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            'Média ${npsMediaTexto(resumo.media)} · ${npsRespostasLabel(resumo.total)}',
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
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
      subtitle: Text(npsItemSubtitle(item)),
      accent: detrator ? EagleTokens.bad : null,
      trailing: Text(
        '${item.score}',
        style: FocuxHubTypography.bodyMuted(
          color: switch (npsClasseDe(item.score)) {
            NpsClasse.promotor => Theme.of(context).colorScheme.primary,
            NpsClasse.neutro => fxScreenMute(context),
            NpsClasse.detrator => EagleTokens.bad,
          },
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onContatar,
    );
  }
}

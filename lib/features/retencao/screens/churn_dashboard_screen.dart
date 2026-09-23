import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';
import '../widgets/retencao_acoes_sheet.dart';
import '../widgets/retencao_catalog_sheet.dart';

final retencaoRepositoryProvider = Provider(
  (ref) => RetencaoRepository(ref.read(apiClientProvider)),
);

class ChurnDashboardScreen extends ConsumerStatefulWidget {
  const ChurnDashboardScreen({super.key});

  @override
  ConsumerState<ChurnDashboardScreen> createState() =>
      _ChurnDashboardScreenState();
}

class _ChurnDashboardScreenState extends ConsumerState<ChurnDashboardScreen> {
  RetencaoHome? _home;
  bool _loading = true;
  String? _error;
  var _filtro = '';
  final _openedAt = DateTime.now();
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.retencaoHubViewed,
      props: {
        'alto': _home?.alto ?? 0,
        'medio': _home?.medio ?? 0,
      },
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.retencaoHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(retencaoRepositoryProvider).getHome();
      if (!mounted) return;
      setState(() {
        _home = home;
        _loading = false;
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  void _abrirAluno(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(
      ProductEvents.alertaRiscoOpened,
      props: {'alunoId': score.alunoId},
    );
    context.push('/alunos/${score.alunoId}');
  }

  void _abrirChat(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(
      ProductEvents.chatThreadOpened,
      props: {'alunoId': score.alunoId},
    );
    context.push('/alunos/${score.alunoId}/chat', extra: score.alunoNome);
  }

  void _abrirCobranca(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(ProductEvents.financeiroViewed);
    context.push('/financeiro?alunoId=${score.alunoId}');
  }

  void _abrirAcoes(RetencaoAlunoScore score) {
    showRetencaoAcoesSheet(
      context,
      score: score,
      onAluno: () => _abrirAluno(score),
      onChat: () => _abrirChat(score),
      onCobrar: () => _abrirCobranca(score),
    );
  }

  Future<void> _abrirMaisHubs() async {
    final chosen = await showFxInsetPickerSheet<RetencaoHubLinkId>(
      context,
      title: 'Hubs relacionados',
      headerIcon: Icons.apps_outlined,
      selected: null,
      items: [
        for (final id in retencaoHubLinks)
          FxInsetPickerSheetItem(
            value: id,
            label: retencaoHubLinkLabel(id),
          ),
      ],
    );
    if (chosen == null || !mounted) return;
    HapticFeedback.selectionClick();
    context.push(retencaoHubLinkRoute(chosen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final home = _home;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(home?.fetchedAt);

    return fxScreenA11yScope(
      label: 'Saúde da base',
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Saúde da base',
          subtitle: freshnessLabel ?? 'Score de retenção por aluno',
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          actions: [
            ShellHeaderIconButton(
              icon: 'route',
              tooltip: 'Mais hubs',
              onTap: _abrirMaisHubs,
            ),
            const SizedBox(width: FxHelpChrome.gap),
            FxHelpIconButton(
              tooltip: 'Como usar a retenção',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.retencaoHubHelpOpened,
                );
                showFxHelpSheet(
                    context,
                    title: 'Saúde da base',
                    subtitle: 'Quem está em risco e o que fazer agora.',
                    tips: const [
                      FxHelpTip('Como calculamos', retencaoComoCalculamos),
                      FxHelpTip(
                        'Risco alto',
                        'O card do topo é quem precisa de contato hoje.',
                      ),
                      FxHelpTip(
                        'Lista',
                        'Os 3 primeiros já vêm do servidor. Ver todos abre a base paginada.',
                      ),
                      FxHelpTip(
                        'Satélites',
                        'Histórico win-back guarda os pushes. Cobrança auto lista falhas de pagamento.',
                      ),
                    ],
                  );
              },
            ),
          ],
        ),
        body:
            _loading
                ? const SkeletonList(count: 6)
                : _error != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: _error!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  color: primary,
                  onRefresh: () async {
                    AnalyticsService.instance.track(
                      ProductEvents.retencaoHubRefreshed,
                    );
                    await _load();
                  },
                  child:
                      home == null || home.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'activity',
                                title: retencaoEmptyTitle,
                                subtitle: retencaoEmptySubtitle,
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
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                TokensStrip.s3,
                                FxSettingsLayout.pageInset,
                                TokensStrip.s6,
                              ),
                              children: [
                                _RetencaoMetricStrip(
                                  home: home,
                                  isDark: isDark,
                                  primary: primary,
                                  onFiltrarAlto: () => setState(
                                    () => _filtro = retencaoFiltroAlto,
                                  ),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                _RetencaoFocusCard(
                                  home: home,
                                  isDark: isDark,
                                  onAluno: _abrirAluno,
                                  onChat: _abrirChat,
                                  onCobrar: _abrirCobranca,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                DashboardSectionHeader(
                                  title: 'Quem olhar agora',
                                  actionLabel:
                                      home.alto + home.medio + home.saudavel > 3
                                          ? 'Ver todos'
                                          : null,
                                  onAction:
                                      home.alto + home.medio + home.saudavel > 3
                                          ? () {
                                            showRetencaoCatalogSheet(
                                              context,
                                              repo: ref.read(
                                                retencaoRepositoryProvider,
                                              ),
                                              onAbrir: _abrirAcoes,
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
                                      selected: _filtro.isEmpty,
                                      isDark: isDark,
                                      onTap: () => setState(() => _filtro = ''),
                                    ),
                                    FxToggleChip(
                                      label: 'Risco alto',
                                      selected: _filtro == retencaoFiltroAlto,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () => _filtro = retencaoFiltroAlto,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                if (retencaoItemsForFiltro(
                                  home.top3,
                                  _filtro,
                                ).isEmpty)
                                  const FxEmptyState(
                                    icon: 'activity',
                                    title: 'Ninguém neste recorte',
                                    subtitle:
                                        'Os scores altos desta leitura aparecem aqui.',
                                  )
                                else
                                  for (final score in retencaoItemsForFiltro(
                                    home.top3,
                                    _filtro,
                                  ))
                                    _RetencaoTile(
                                      score: score,
                                      isDark: isDark,
                                      onChat: () => _abrirChat(score),
                                      onAluno: () => _abrirAluno(score),
                                      onMais: () => _abrirAcoes(score),
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

class _RetencaoMetricStrip extends StatelessWidget {
  const _RetencaoMetricStrip({
    required this.home,
    required this.isDark,
    required this.primary,
    required this.onFiltrarAlto,
  });

  final RetencaoHome home;
  final bool isDark;
  final Color primary;
  final VoidCallback onFiltrarAlto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: home.alto > 0 ? onFiltrarAlto : null,
            borderRadius: BorderRadius.circular(12),
            child: OperationalMetricTile(
              label: 'Alto',
              value: '${home.alto}',
              hint: retencaoMetricAltoLabel(home.alto),
              color: primary,
              isDark: isDark,
              emphasis:
                  home.alto > 0
                      ? OperationalMetricEmphasis.normal
                      : OperationalMetricEmphasis.muted,
              semanticsLabel: '${home.alto} em risco alto',
            ),
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: OperationalMetricTile(
            label: 'Médio',
            value: '${home.medio}',
            hint: retencaoMetricMedioLabel(home.medio),
            color: EagleTokens.warn,
            isDark: isDark,
            emphasis: OperationalMetricEmphasis.muted,
            semanticsLabel: '${home.medio} risco médio',
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: OperationalMetricTile(
            label: 'Saudável',
            value: '${home.saudavel}',
            hint: retencaoMetricSaudavelLabel(home.saudavel),
            color: primary,
            isDark: isDark,
            emphasis: OperationalMetricEmphasis.muted,
            semanticsLabel: '${home.saudavel} saudáveis',
          ),
        ),
      ],
    );
  }
}

class _RetencaoFocusCard extends StatelessWidget {
  const _RetencaoFocusCard({
    required this.home,
    required this.isDark,
    required this.onAluno,
    required this.onChat,
    required this.onCobrar,
  });

  final RetencaoHome home;
  final bool isDark;
  final void Function(RetencaoAlunoScore score) onAluno;
  final void Function(RetencaoAlunoScore score) onChat;
  final void Function(RetencaoAlunoScore score) onCobrar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final alto = home.alto;
    final firstAlto = firstAltoRetencao(home.top3);
    final split = retencaoFocusActions(hasAlto: firstAlto != null);

    VoidCallback run(RetencaoFocusActionId id) => switch (id) {
      RetencaoFocusActionId.chat => () => onChat(firstAlto!),
      RetencaoFocusActionId.cobrar => () => onCobrar(firstAlto!),
      RetencaoFocusActionId.aluno360 => () => onAluno(firstAlto!),
      RetencaoFocusActionId.verAlunos => () {
        AnalyticsService.instance.track(ProductEvents.alunosViewed);
        goPersonalShellTab(context, '/alunos');
      },
    };

    Future<void> openMais() async {
      final chosen = await showFxInsetPickerSheet<RetencaoFocusActionId>(
        context,
        title: 'Mais ações',
        headerIcon: Icons.more_horiz_rounded,
        selected: null,
        items: [
          for (final id in split.secondary)
            FxInsetPickerSheetItem(
              value: id,
              label: retencaoFocusActionLabel(id),
            ),
        ],
      );
      if (chosen == null) return;
      HapticFeedback.selectionClick();
      run(chosen)();
    }

    final focusTitle =
        firstAlto != null
            ? firstAlto.alunoNome
            : (alto == 0
                ? 'Ninguém em alerta agora'
                : alto == 1
                ? '1 aluno em risco alto'
                : '$alto alunos em risco alto');

    final focusSubtitle =
        firstAlto != null
            ? retencaoPorque(firstAlto)
            : retencaoContagensSubtitulo(
              alto: home.alto,
              medio: home.medio,
              saudavel: home.saudavel,
              topNomeados: retencaoItemsForFiltro(home.top3, null).length,
            );

    return FxStripCard(
      emphasize: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          alto == 0
              ? 'Nenhum aluno em risco alto'
              : '$alto em risco alto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstAlto != null ? 'Próximo contato' : 'Risco alto · $alto',
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            focusTitle,
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            focusSubtitle,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: retencaoFocusActionLabel(split.primary),
                accent: primary,
                isDark: isDark,
                onPressed: run(split.primary),
              ),
              if (firstAlto != null)
                DashboardHomeActionChip(
                  label: retencaoFocusActionLabel(
                    RetencaoFocusActionId.aluno360,
                  ),
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: () => onAluno(firstAlto),
                ),
              if (split.secondary.any(
                (id) => id != RetencaoFocusActionId.aluno360,
              ))
                DashboardHomeActionChip(
                  label: 'Mais ações',
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: openMais,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetencaoTile extends StatelessWidget {
  const _RetencaoTile({
    required this.score,
    required this.isDark,
    required this.onChat,
    required this.onAluno,
    required this.onMais,
  });

  final RetencaoAlunoScore score;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onAluno;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final alto = retencaoRiscoAlto(score.riscoChurn);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = ShellChrome.of(context).mute;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: FxSatelliteListTile(
        title: score.alunoNome,
        subtitle: Text(retencaoPorque(score)),
        accent: alto ? primary : null,
        onTap: onAluno,
        onLongPress: onMais,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardHomeActionChip(
              label: retencaoFocusActionLabel(RetencaoFocusActionId.chat),
              accent: primary,
              isDark: isDark,
              onPressed: onChat,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Mais ações',
              onPressed: onMais,
              icon: Icon(Icons.more_horiz_rounded, color: mute, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

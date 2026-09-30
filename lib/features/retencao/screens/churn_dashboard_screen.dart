import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/brand/focux_microcopy.dart';
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
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';
import '../widgets/retencao_acoes_sheet.dart';
import '../widgets/retencao_catalog_sheet.dart';

part 'churn_dashboard_screen_cards.part.dart';

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
      title: retencaoHubsRelacionados,
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
      label: FocuxMicrocopy.saudeDaBase,
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: FocuxMicrocopy.saudeDaBase,
          subtitle: freshnessLabel ?? retencaoDefaultSubtitle,
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          actions: [
            ShellHeaderIconButton(
              icon: 'route',
              tooltip: retencaoMaisHubs,
              onTap: _abrirMaisHubs,
            ),
            const SizedBox(width: FxHelpChrome.gap),
            FxHelpIconButton(
              tooltip: retencaoComoUsar,
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.retencaoHubHelpOpened,
                );
                showFxHelpSheet(
                    context,
                    title: FocuxMicrocopy.saudeDaBase,
                    subtitle: retencaoHelpSubtitle,
                    tips: const [
                      FxHelpTip(retencaoComoCalculamosTitle, retencaoComoCalculamos),
                      FxHelpTip(
                        retencaoRiscoChurnTitle,
                        retencaoHelpRiscoBody,
                      ),
                      FxHelpTip(
                        retencaoHelpListaTitle,
                        retencaoHelpListaBody,
                      ),
                      FxHelpTip(
                        retencaoHelpSatelitesTitle,
                        retencaoHelpSatelitesBody,
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
                                  label: retencaoFocusActionLabel(
                                    RetencaoFocusActionId.verAlunos,
                                  ),
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
                                  title: retencaoQuemOlhar,
                                  actionLabel:
                                      home.alto + home.medio + home.saudavel > 3
                                          ? retencaoVerTodos
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
                                      label: retencaoFiltroTodos,
                                      selected: _filtro.isEmpty,
                                      isDark: isDark,
                                      onTap: () => setState(() => _filtro = ''),
                                    ),
                                    FxToggleChip(
                                      label: retencaoRiscoLabel('ALTO'),
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
                                    title: retencaoNinguemRecorte,
                                    subtitle:
                                        retencaoNinguemRecorteSubtitle,
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

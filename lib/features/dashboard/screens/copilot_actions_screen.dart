import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import '../utils/copilot_actions_display.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

part 'copilot_actions_screen_widgets.part.dart';

typedef IaActionsQuery = ({String status, String q});

final iaActionsProvider =
    FutureProvider.family<IaCommandActionsPage, IaActionsQuery>((ref, query) {
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActionsPage(status: query.status, q: query.q);
    });

class CopilotActionsScreen extends ConsumerStatefulWidget {
  const CopilotActionsScreen({super.key});

  @override
  ConsumerState<CopilotActionsScreen> createState() =>
      _CopilotActionsScreenState();
}

class _CopilotActionsScreenState extends ConsumerState<CopilotActionsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _status = copilotActionsStatusAberto;
  String _query = '';
  final _extra = <FilaAcaoResumo>[];
  var _extraHasNext = false;
  var _extraPage = 0;
  var _loadingMore = false;
  DateTime? _fetchedAt;

  IaActionsQuery get _queryKey => (status: _status, q: _query);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    ref.listen<AsyncValue<IaCommandActionsPage>>(iaActionsProvider(_queryKey), (
      _,
      next,
    ) {
      if (!next.isLoading && next.hasValue) {
        setState(() {
          _fetchedAt = DateTime.now();
          _extra.clear();
          _extraHasNext = false;
          _extraPage = 0;
        });
      }
    });
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final actionsAsync = ref.watch(iaActionsProvider(_queryKey));

    return fxScreenA11yScope(
      label: 'Tarefas IA',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Tarefas IA',
          subtitle:
              FxHubFreshness.fromFetchedAt(_fetchedAt) ?? 'Centro de Comando',
          onBack: () => safePopOrGo(context, '/ia/copiloto'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funcionam as tarefas IA',
              onTap: _abrirAjuda,
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                2,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlunoSegmentedChoice(
                    options: [
                      for (final status in copilotActionsStatusValues)
                        (
                          value: status,
                          label: copilotActionsStatusLabel(status),
                        ),
                    ],
                    selected: _status,
                    isDark: dark,
                    onSelect: _selecionarStatus,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                    onTapOutside:
                        (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: FxInputDeco.build(context, 'Buscar tarefa'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: actionsAsync.when(
                loading: () => const SkeletonList(count: 6),
                error:
                    (e, _) => FxErrorState(
                      chromeOnDark: dark,
                      primary: brand,
                      message: friendlyError(e),
                      onRetry: _refresh,
                    ),
                data: (page) {
                  final seen = page.itens.map((item) => item.actionKey).toSet();
                  final actions = [
                    ...page.itens,
                    ..._extra.where((item) => seen.add(item.actionKey)),
                  ];
                  final hasNext =
                      _extra.isEmpty ? page.hasNext : _extraHasNext;
                  final copilot =
                      actions
                          .where((action) => action.tipo == 'IA_COPILOTO')
                          .toList();
                  final radar =
                      actions
                          .where((action) => action.tipo != 'IA_COPILOTO')
                          .toList();

                  if (actions.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s4,
                          FxSettingsLayout.pageInset,
                          120,
                        ),
                        children: [
                          FxEmptyState(
                            icon: 'circle-check',
                            title: copilotActionsEmptyTitle(_status),
                            subtitle: copilotActionsEmptySubtitle(_status),
                            action: FxEmptyAction(
                              label: copilotActionsAtualizarLabel(),
                              onTap: _refresh,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        10,
                        FxSettingsLayout.pageInset,
                        120,
                      ),
                      children: [
                        if (copilot.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Copiloto',
                            detail: copilotActionsSectionDetail(
                              _status,
                              copilot.length,
                            ),
                            ink: ink,
                            mute: mute,
                          ),
                          const SizedBox(height: 8),
                          for (final entry in copilot.asMap().entries) ...[
                            _CopilotTaskCard(
                              action: entry.value,
                              status: _status,
                              highlighted:
                                  _status == copilotActionsStatusAberto &&
                                  entry.key == 0,
                              ink: ink,
                              mute: mute,
                              brand: brand,
                              onOpen: () => _openAction(context, entry.value),
                              onComplete: () => _complete(entry.value),
                              onSnooze: () => _snooze(entry.value),
                              onReopen: () => _reopen(entry.value),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        if (radar.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _SectionHeader(
                            title: 'Sinais automáticos',
                            detail:
                                radar.length == 1
                                    ? '1 sinal'
                                    : '${radar.length} sinais',
                            ink: ink,
                            mute: mute,
                          ),
                          const SizedBox(height: 8),
                          for (final action in radar) ...[
                            _RadarSignalCard(
                              action: action,
                              status: _status,
                              ink: ink,
                              mute: mute,
                              brand: brand,
                              onOpen: () => _openAction(context, action),
                              onComplete: () => _complete(action),
                              onSnooze: () => _snooze(action),
                              onReopen: () => _reopen(action),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        if (hasNext)
                          FxSatelliteListTile(
                            title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                            subtitle:
                                _loadingMore
                                    ? null
                                    : Text(
                                      'Mais ${(page.totalItens - actions.length).clamp(0, 999)} nesta lista.',
                                    ),
                            onTap: _loadingMore ? null : () => _carregarMais(page),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _selecionarStatus(String picked) {
    if (picked == _status) return;
    setState(() {
      _status = picked;
      _extra.clear();
      _extraHasNext = false;
      _extraPage = 0;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _onSearchSubmitted(value);
    });
  }

  void _onSearchSubmitted(String value) {
    final next = value.trim();
    if (next == _query) return;
    setState(() {
      _query = next;
      _extra.clear();
      _extraHasNext = false;
      _extraPage = 0;
    });
  }

  Future<void> _carregarMais(IaCommandActionsPage first) async {
    if (_loadingMore) return;
    final currentPage = _extra.isEmpty ? first.page : _extraPage;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActionsPage(
            status: _status,
            q: _query,
            page: currentPage + 1,
          );
      if (!mounted) return;
      setState(() {
        _extra.addAll(next.itens);
        _extraPage = next.page;
        _extraHasNext = next.hasNext;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _abrirAjuda() {
    showFxHelpSheet(
      context,
      title: copilotActionsHelpTitle(),
      subtitle: copilotActionsHelpSubtitle(),
      tips: const [
        FxHelpTip('Como calculamos', copilotActionsComoCalculamos),
        FxHelpTip(
          'Copiloto',
          'Tarefas que você salvou a partir de um insight. Revisar o aluno não conclui a tarefa.',
        ),
        FxHelpTip(
          'Sinais',
          'Alertas automáticos do Radar. Concluir, adiar ou reabrir pede confirmação.',
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    _extra.clear();
    _extraHasNext = false;
    _extraPage = 0;
    ref.invalidate(iaActionsProvider(_queryKey));
    await ref.read(iaActionsProvider(_queryKey).future);
  }

  void _openAction(BuildContext context, FilaAcaoResumo action) {
    if (action.acaoUrl.startsWith('/')) {
      context.push(action.acaoUrl);
    }
  }

  Future<void> _complete(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsCompleteConfirmTitle(),
      message: copilotActionsCompleteConfirmMessage(),
      confirmLabel: copilotActionsConcluirLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .completeCommandAction(action.actionKey),
      'Tarefa concluída',
    );
  }

  Future<void> _snooze(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsSnoozeConfirmTitle(),
      message: copilotActionsSnoozeConfirmMessage(),
      confirmLabel: copilotActionsAdiarLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .snoozeCommandAction(action.actionKey, hours: 24),
      'Tarefa adiada por 24h',
    );
  }

  Future<void> _reopen(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsReopenConfirmTitle(),
      message: copilotActionsReopenConfirmMessage(),
      confirmLabel: copilotActionsReabrirLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .reopenCommandAction(action.actionKey),
      'Tarefa reaberta',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(iaActionsProvider(_queryKey));
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(commandCenterProvider);
      FeedbackHelper.showInfo(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível atualizar a tarefa.'),
      );
    }
  }
}

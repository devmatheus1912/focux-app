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
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../ia/providers/ia_copilot_providers.dart';
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

final iaActionsContagemProvider = FutureProvider.autoDispose
    .family<IaCommandActionsContagem, String>((ref, q) {
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActionsContagem(q: q);
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
    final contagem = ref.watch(iaActionsContagemProvider(_query)).value;

    return fxScreenA11yScope(
      label: 'Tarefas',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Tarefas',
          subtitle:
              FxHubFreshness.fromFetchedAt(_fetchedAt),
          onBack: () => safePopOrGo(context, '/ia/copiloto'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funcionam as tarefas',
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
                          label: copilotActionsStatusChoiceLabel(
                            status,
                            contagem,
                          ),
                        ),
                    ],
                    selected: _status,
                    isDark: dark,
                    onSelect: _selecionarStatus,
                  ),
                  if (_query.isNotEmpty || _totalNaLista(contagem) > 10) ...[
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
                        Container(
                          decoration: fxListCardDecoration(context),
                          child: Column(
                            children: [
                              for (final (i, action)
                                  in copilotActionsOrdenadas(actions).indexed) ...[
                                if (i > 0) const Divider(height: 1),
                                _TarefaRow(
                                  action: action,
                                  concluida:
                                      _status == copilotActionsStatusConcluido,
                                  ink: ink,
                                  mute: mute,
                                  onOpen: () => _openAction(context, action),
                                  onMais: () => _abrirAcoes(action),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
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

  int _totalNaLista(IaCommandActionsContagem? contagem) {
    if (contagem == null) return 0;
    return switch (_status) {
      copilotActionsStatusAdiado => contagem.adiadas,
      copilotActionsStatusConcluido => contagem.concluidas,
      _ => contagem.abertas,
    };
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
          'O que aparece aqui',
          'Tarefas salvas do Copiloto e alertas automáticos. Abrir o aluno não conclui a tarefa.',
        ),
        FxHelpTip(
          'Adiar e concluir',
          'Toque em "⋯". Por alguns segundos dá para desfazer.',
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    _extra.clear();
    _extraHasNext = false;
    _extraPage = 0;
    ref.invalidate(iaActionsProvider(_queryKey));
    ref.invalidate(iaActionsContagemProvider(_query));
    await ref.read(iaActionsProvider(_queryKey).future);
  }

  void _openAction(BuildContext context, FilaAcaoResumo action) {
    final destino = copilotActionsDestino(action);
    if (destino.startsWith('/')) context.push(destino);
  }

  Future<void> _abrirAcoes(FilaAcaoResumo action) async {
    final concluida = _status == copilotActionsStatusConcluido;
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: copilotActionsNome(action),
      subtitulo: copilotActionsMotivo(action),
      icone: Icons.checklist_rounded,
      grupos: [
        FxActionGroup<String>(null, [
          if (concluida)
            FxActionItem(
              valor: 'reabrir',
              rotulo: copilotActionsReabrirLabel(),
              icone: Icons.undo_rounded,
            )
          else ...[
            FxActionItem(
              valor: 'adiar',
              rotulo: copilotActionsAdiarLabel(),
              icone: Icons.schedule_rounded,
            ),
            FxActionItem(
              valor: 'concluir',
              rotulo: copilotActionsConcluirLabel(),
              icone: Icons.check_rounded,
            ),
          ],
        ]),
      ],
    );
    if (!mounted || escolha == null) return;
    final repo = ref.read(dashboardRepositoryProvider);
    switch (escolha) {
      case 'concluir':
        await _runAction(
          () => repo.completeCommandAction(action.actionKey),
          'Tarefa concluída',
          undo: action,
        );
      case 'adiar':
        await _runAction(
          () => repo.snoozeCommandAction(action.actionKey, hours: 24),
          'Tarefa adiada por 24h',
          undo: action,
        );
      case 'reabrir':
        await _runAction(
          () => repo.reopenCommandAction(action.actionKey),
          'Tarefa reaberta',
        );
    }
  }

  void _recarregar() {
    ref.invalidate(iaActionsProvider(_queryKey));
    ref.invalidate(iaActionsContagemProvider(_query));
    invalidatePersonalDashboardHome(ref);
    ref.invalidate(commandCenterProvider);
    ref.invalidate(copilotoTarefasAbertasProvider);
  }

  /// Sem folha de confirmação: a ação vale na hora e [undo] oferece desfazer.
  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage, {
    FilaAcaoResumo? undo,
  }) async {
    try {
      await action();
      if (!mounted) return;
      _recarregar();
      if (undo == null) {
        FeedbackHelper.showInfo(context, successMessage);
        return;
      }
      final desfazer = await FeedbackHelper.showUndo(
        context,
        successMessage,
        duration: const Duration(seconds: 6),
      );
      if (!desfazer || !mounted) return;
      await ref.read(dashboardRepositoryProvider).reopenCommandAction(undo.actionKey);
      if (mounted) _recarregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(
        context,
        e,
        fallback: 'Não foi possível atualizar a tarefa.',
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_barra_progresso.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';
import '../widgets/habito_editar_sheet.dart';
import '../../../core/theme/fx_icons.dart';

class HabitoDetailScreen extends ConsumerStatefulWidget {
  const HabitoDetailScreen({
    super.key,
    required this.habitoId,
    this.habito,
    this.forAluno = false,
  });

  final int habitoId;
  final Habito? habito;
  final bool forAluno;

  @override
  ConsumerState<HabitoDetailScreen> createState() => _HabitoDetailScreenState();
}

class _HabitoDetailScreenState extends ConsumerState<HabitoDetailScreen> {
  Habito? _habito;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _busy = false;
  List<HabitoSemanaAluno>? _semana;

  String get _parent => widget.forAluno ? '/aluno/habitos' : '/habitos';

  @override
  void initState() {
    super.initState();
    _habito = widget.habito;
    _load();
  }

  void _leave() => safePopOrGo(context, _parent);

  HabitoRepository get _repo => HabitoRepository(ref.read(apiClientProvider));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final found = await _repo.buscar(widget.habitoId);
      // Personal vê cada aluno desta semana; sem a lista, o resto aparece.
      List<HabitoSemanaAluno>? semana;
      if (!widget.forAluno) {
        try {
          semana = await _repo.semana(widget.habitoId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _habito = found;
        _semana = semana;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_habito == null) {
          _erro = friendlyError(e);
        }
        _loading = false;
      });
    }
  }

  Future<void> _maisOpcoes() async {
    final habito = _habito;
    if (habito == null || _busy) return;
    // Sem excluir: apagaria as marcações e a sequência dos alunos.
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: habito.titulo,
      grupos: [
        FxActionGroup('Hábito', [
          if (habito.ativo)
            const FxActionItem(
              valor: 'editar',
              rotulo: 'Editar',
              icone: FxIcons.editar,
              descricao: 'Nome, vezes por semana e descrição.',
            ),
          if (!habito.ativo)
            const FxActionItem(
              valor: 'reativar',
              rotulo: 'Reativar',
              icone: FxIcons.atualizar,
              descricao: 'Volta para a lista dos alunos.',
            ),
        ]),
      ],
      destrutiva:
          habito.ativo
              ? const FxActionItem(
                valor: 'desativar',
                rotulo: 'Desativar',
                icone: FxIcons.fechar,
              )
              : null,
      confirmar: false,
    );
    if (!mounted) return;
    if (acao == 'editar') {
      final salvou = await showHabitoEditarSheet(
        context,
        habito: habito,
        repo: _repo,
      );
      if (!mounted || !salvou) return;
      FeedbackHelper.showSuccess(context, 'Hábito salvo');
      await _load();
      return;
    }
    if (acao == 'desativar') {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Desativar o hábito?',
        message:
            'Os alunos param de ver e de marcar. As marcações antigas ficam, e dá para reativar.',
        confirmLabel: 'Desativar',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    if (acao != 'desativar' && acao != 'reativar') return;
    setState(() => _busy = true);
    try {
      if (acao == 'desativar') {
        await _repo.desativar(habito.id);
      } else {
        await _repo.reativar(habito.id);
      }
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        acao == 'desativar' ? 'Hábito desativado' : 'Hábito reativado',
      );
      if (acao == 'desativar') {
        _leave();
      } else {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleHoje() async {
    final habito = _habito;
    if (habito == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await _repo.toggleHoje(habito.id);
      if (!mounted) return;
      setState(() {
        _habito = habito.copyWith(
          feitoHoje: result.feito,
          streakAtual: result.streak,
          feitosNaSemana:
              result.feito
                  ? habito.feitosNaSemana + 1
                  : (habito.feitosNaSemana - 1).clamp(0, 7),
          badgeSemana: result.streak >= 7,
          checks: habitoPatchCheckHoje(habito.checks, result.feito),
        );
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final habito = _habito;
    final titulo = habito?.titulo ?? 'Hábito';

    return fxScreenA11yScope(
      label: titulo,
      child: FeatureGate(
        featureName: 'Habit Coaching',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'habitCoaching',
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _leave();
          },
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Hábito',
              subtitle:
                  habito == null
                      ? null
                      : FxHubFreshness.fromFetchedAt(_fetchedAt),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar este hábito',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Hábito',
                        subtitle:
                            'Quantas vezes por semana e quem está em dia.',
                        tips: [
                          const FxHelpTip('Esta semana', habitoComoCalculamos),
                          FxHelpTip(
                            widget.forAluno ? 'Marcar' : 'Editar ou desativar',
                            widget.forAluno
                                ? 'O botão marca ou desmarca o dia de hoje.'
                                : 'No ⋯ do topo. Desativado volta com Reativar.',
                          ),
                        ],
                      ),
                ),
                if (!widget.forAluno && habito != null)
                  IconButton(
                    tooltip: 'Mais opções',
                    onPressed: _busy ? null : _maisOpcoes,
                    icon: const Icon(FxIcons.mais),
                  ),
              ],
            ),
            body:
                _loading && habito == null
                    ? const Padding(
                      padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                      child: SkeletonList(count: 5),
                    )
                    : _erro != null && habito == null
                    ? FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _erro!,
                      onRetry: _load,
                    )
                    : habito == null
                    ? FxEmptyState(
                      icon: FxIcons.concluido,
                      title: 'Hábito não encontrado',
                      subtitle:
                          'Ele pode ter sido desativado. Volte à lista e escolha outro.',
                      action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                    )
                    : _HabitoDetailBody(
                      habito: habito,
                      forAluno: widget.forAluno,
                      busy: _busy,
                      semana: _semana,
                      onRefresh: _load,
                      onMarcar: _toggleHoje,
                    ),
          ),
        ),
      ),
    );
  }
}

class _HabitoDetailBody extends StatelessWidget {
  const _HabitoDetailBody({
    required this.habito,
    required this.forAluno,
    required this.busy,
    required this.semana,
    required this.onRefresh,
    required this.onMarcar,
  });

  final Habito habito;
  final bool forAluno;
  final bool busy;
  final List<HabitoSemanaAluno>? semana;
  final Future<void> Function() onRefresh;
  final VoidCallback onMarcar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final sobre = fxPaletaSobreMarca(context, accent: primary);
    final descricao = habito.descricao?.trim() ?? '';
    final sequencia = habitoSequenciaLinha(habito.streakAtual);
    final lembrete = habitoLembreteLine(habito.lembreteHora);
    final marcacoes = habitoChecksLine(habito.checks);
    final alunos = semana;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primary,
            onRefresh: onRefresh,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6,
                ),
                children: [
                  FxStripCard(
                    marca: true,
                    accent: primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habito.titulo,
                          style: FocuxHubTypography.cardTitle(color: sobre.ink),
                        ),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          forAluno
                              ? habitoVezesPorSemana(habito.metaSemanal)
                              : habitoRegra(
                                metaSemanal: habito.metaSemanal,
                                alunoId: habito.alunoId,
                              ),
                          style: FocuxHubTypography.bodyMuted(
                            color: sobre.mute,
                          ),
                        ),
                        if (!habito.ativo) ...[
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            'Desativado',
                            style: FocuxHubTypography.rotulo(color: sobre.ink),
                          ),
                        ],
                        if (forAluno) ...[
                          const SizedBox(height: TokensStrip.s3),
                          Text(
                            habitoSemanaLinha(
                              habito.feitosNaSemana,
                              habito.metaSemanal,
                            ),
                            style: FocuxHubTypography.body(color: sobre.ink),
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          FxBarraProgresso(
                            fracao: habitoFracao(
                              habito.feitosNaSemana,
                              habito.metaSemanal,
                            ),
                            cor: sobre.ink,
                          ),
                          if (sequencia.isNotEmpty) ...[
                            const SizedBox(height: TokensStrip.s2),
                            Text(
                              sequencia,
                              style: FocuxHubTypography.bodyMuted(
                                color: sobre.mute,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (descricao.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s3),
                    Text(
                      descricao,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                  if (forAluno) ...[
                    for (final linha in [lembrete, marcacoes])
                      if (linha.isNotEmpty) ...[
                        const SizedBox(height: TokensStrip.s2),
                        Text(
                          linha,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                          ),
                        ),
                      ],
                  ] else ...[
                    const SizedBox(height: TokensStrip.s5),
                    const DashboardSectionHeader(title: 'Esta semana'),
                    const SizedBox(height: TokensStrip.s2),
                    if (alunos == null)
                      Text(
                        'Não deu para carregar os alunos agora. Puxe para atualizar.',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      )
                    else if (alunos.isEmpty)
                      Text(
                        'Nenhum aluno ativo com este hábito.',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      )
                    else
                      for (final a in [...alunos]..sort(
                        (x, y) => habitoFracao(
                          x.feitos,
                          x.meta,
                        ).compareTo(habitoFracao(y.feitos, y.meta)),
                      ))
                        InkWell(
                          onTap: () => context.push('/alunos/${a.alunoId}'),
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rCard,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: TokensStrip.s2,
                              horizontal: TokensStrip.s1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        habitoComplianceLabel(a.nome),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FocuxHubTypography.body(
                                          color: chrome.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${a.feitos} de ${a.meta}',
                                      style: FocuxHubTypography.rotulo(
                                        color: chrome.mute,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TokensStrip.s1),
                                FxBarraProgresso(
                                  fracao: habitoFracao(a.feitos, a.meta),
                                  cor:
                                      a.meta > 0 && a.feitos >= a.meta
                                          ? EagleTokens.good
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (forAluno && habito.ativo)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: FxLiquidPrimaryButton(
                label: habitoStickyAluno(habito.feitoHoje),
                loading: busy,
                onPressed: busy ? null : onMarcar,
              ),
            ),
          ),
      ],
    );
  }
}

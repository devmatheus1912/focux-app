import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

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
  var _secao = habitoDetalheSecaoResumo;

  String get _parent => widget.forAluno ? '/aluno/habitos' : '/habitos';

  @override
  void initState() {
    super.initState();
    _habito = widget.habito;
    _load();
  }

  void _leave() => safePopOrGo(context, _parent);

  HabitoRepository get _repo =>
      HabitoRepository(ref.read(apiClientProvider));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final found = await _repo.buscar(widget.habitoId);
      if (!mounted) return;
      setState(() {
        _habito = found;
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

  Future<void> _desativar() async {
    final habito = _habito;
    if (habito == null || _busy) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Desativar hábito?',
      subtitle: habito.titulo,
      message: habitoDetalheMessage(
        descricao: habito.descricao,
        metaSemanal: habito.metaSemanal,
      ),
      confirmLabel: 'Desativar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.desativar(habito.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Hábito desativado');
      _leave();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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
          feitosNaSemana: result.feito
              ? habito.feitosNaSemana + 1
              : (habito.feitosNaSemana - 1).clamp(0, 7),
          badgeSemana: result.streak >= 7,
          checks: habitoPatchCheckHoje(habito.checks, result.feito),
        );
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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
              subtitle: habito == null
                  ? null
                  : FxHubFreshness.fromFetchedAt(_fetchedAt),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar este hábito',
                  onTap: () => showFxHelpSheet(
                    context,
                    title: 'Hábito',
                    subtitle: 'Meta da semana e o que fazer hoje.',
                    tips: [
                      const FxHelpTip(
                        'Como calculamos',
                        habitoComoCalculamos,
                      ),
                      FxHelpTip(
                        widget.forAluno ? 'Marcar' : 'Desativar',
                        widget.forAluno
                            ? 'O botão marca ou desmarca o check de hoje.'
                            : 'Desativar tira o hábito da lista ativa.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: _loading && habito == null
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
                    icon: 'circle-check',
                    title: 'Hábito não encontrado',
                    subtitle:
                        'Ele pode ter sido desativado. Volte à lista e escolha outro.',
                    action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                  )
                : _HabitoDetailBody(
                    habito: habito,
                    forAluno: widget.forAluno,
                    busy: _busy,
                    secao: _secao,
                    onSecao: (value) => setState(() => _secao = value),
                    onRefresh: _load,
                    onLeave: _leave,
                    onSticky: widget.forAluno ? _toggleHoje : _desativar,
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
    required this.secao,
    required this.onSecao,
    required this.onRefresh,
    required this.onLeave,
    required this.onSticky,
  });

  final Habito habito;
  final bool forAluno;
  final bool busy;
  final String secao;
  final ValueChanged<String> onSecao;
  final Future<void> Function() onRefresh;
  final VoidCallback onLeave;
  final VoidCallback onSticky;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final descricao = habito.descricao?.trim() ?? '';

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
                  24,
                ),
                children: [
                  FxHubHeader(
                    title: habito.titulo,
                    subtitle: habitoDetailSubtitle(
                      metaSemanal: habito.metaSemanal,
                      alunoId: habito.alunoId,
                      ativo: habito.ativo,
                    ),
                  ),
                  if (forAluno && habito.ativo) ...[
                    const SizedBox(height: TokensStrip.s4),
                    FxStripCard(
                      emphasize: true,
                      accent: primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoje',
                            style: FocuxHubTypography.chip(
                              fxScreenMute(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            habito.feitoHoje ? 'Feito' : 'Pendente',
                            style: FocuxHubTypography.kpi(
                              color: fxScreenInk(context),
                              fontSize: FocuxHubTypography.metricLg,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            habito.feitoHoje
                                ? 'Check de hoje registrado'
                                : 'Marque quando concluir',
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          DashboardHomeActionChip(
                            label: habitoStickyAluno(habito.feitoHoje),
                            accent: primary,
                            isDark: isDark,
                            enabled: !busy,
                            onPressed: onSticky,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s4),
                  OperationalMetricTile(
                    label: 'Sequência',
                    value: habitoStreakValue(habito.streakAtual),
                    hint: habitoStreakHint(habito.streakAtual),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Semana',
                    value: habitoFeitosValue(
                      habito.feitosNaSemana,
                      habito.metaSemanal,
                    ),
                    hint: habitoFeitosHint(
                      feitos: habito.feitosNaSemana,
                      meta: habito.metaSemanal,
                    ),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Meta',
                    value: habitoMetaValue(habito.metaSemanal),
                    hint: 'Por semana',
                    color: primary,
                    isDark: isDark,
                  ),
                  if (!forAluno) ...[
                    const SizedBox(height: TokensStrip.s2),
                    OperationalMetricTile(
                      label: 'Alcance',
                      value: habitoAlcanceLabel(habito.alunoId),
                      hint: habito.alunoId == null
                          ? 'Vale para a base'
                          : 'Só este aluno',
                      color: primary,
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s3),
                  Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      DashboardHomeActionChip(
                        label: 'Lista',
                        accent: primary,
                        isDark: isDark,
                        onPressed: onLeave,
                      ),
                      if (forAluno)
                        DashboardHomeActionChip(
                          label: 'Hoje',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => context.push('/dashboard/aluno'),
                        ),
                      if (!forAluno && habito.alunoId != null)
                        DashboardHomeActionChip(
                          label: 'Aluno',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => context.push(
                            '/alunos/${habito.alunoId}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  AlunoSegmentedChoice(
                    options: habitoDetalheSecoes,
                    selected: secao,
                    isDark: isDark,
                    onSelect: onSecao,
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (secao == habitoDetalheSecaoSobre) ...[
                    if (!habito.ativo) ...[
                      Text(
                        habitoDesativadoChip(),
                        style: FocuxHubTypography.bodyMuted(
                          color: fxScreenMute(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                    ],
                    Text(
                      descricao.isEmpty ? habitoSobreEmpty() : descricao,
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    Text(
                      habitoLembreteLine(habito.lembreteHora),
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (habitoChecksLine(habito.checks) case final checksLine
                        when checksLine.isNotEmpty) ...[
                      const SizedBox(height: TokensStrip.s3),
                      Text(
                        checksLine,
                        style: FocuxHubTypography.bodyMuted(
                          color: fxScreenMute(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        if (habito.ativo)
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: FxLiquidPrimaryButton(
                label: forAluno
                    ? habitoStickyAluno(habito.feitoHoje)
                    : habitoStickyPersonal(),
                loading: busy,
                onPressed: busy ? null : onSticky,
              ),
            ),
          ),
      ],
    );
  }
}

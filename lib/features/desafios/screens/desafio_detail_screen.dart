import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

class DesafioDetailScreen extends ConsumerStatefulWidget {
  const DesafioDetailScreen({
    super.key,
    required this.desafioId,
    this.desafio,
    this.forAluno = false,
  });

  final int desafioId;
  final Desafio? desafio;
  final bool forAluno;

  @override
  ConsumerState<DesafioDetailScreen> createState() =>
      _DesafioDetailScreenState();
}

class _DesafioDetailScreenState extends ConsumerState<DesafioDetailScreen> {
  Desafio? _desafio;
  List<DesafioLeaderboardEntry> _ranking = [];
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _encerrando = false;
  var _secao = desafioSecaoRanking;

  String get _parent =>
      widget.forAluno ? '/aluno/desafios' : '/desafios';

  @override
  void initState() {
    super.initState();
    _desafio = widget.desafio;
    _load();
  }

  void _leave() => safePopOrGo(context, _parent);

  DesafioRepository get _repo =>
      DesafioRepository(ref.read(apiClientProvider));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (widget.forAluno) {
        await _repo.participar(widget.desafioId);
      }
      final found = await _repo.buscar(widget.desafioId);
      final ranking = found.ranking ?? await _repo.leaderboard(widget.desafioId);
      if (!mounted) return;
      setState(() {
        _desafio = found;
        _ranking = ranking;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _encerrar() async {
    final desafio = _desafio;
    if (desafio == null || _encerrando) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Encerrar desafio?',
      subtitle: desafio.titulo,
      message: 'Sai da lista ativa. O ranking deixa de pontuar.',
      confirmLabel: 'Encerrar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _encerrando = true);
    try {
      await _repo.encerrar(desafio.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Desafio encerrado');
      _leave();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _encerrando = false);
    }
  }

  void _alunoSticky() {
    final tipo = _desafio?.tipo ?? 'HABITOS';
    context.push(desafioStickyAlunoPath(tipo));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final desafio = _desafio;
    final titulo = desafio?.titulo ?? 'Desafio';
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final meId =
        widget.forAluno
            ? ref.watch(alunoMeProvider).valueOrNull?.id
            : null;

    return fxScreenA11yScope(
      label: titulo,
      child: FeatureGate(
        featureName: 'Desafios',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'comunidadeGrupos',
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
              title: 'Desafio',
              subtitle: freshness,
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar este desafio',
                  onTap: () => showFxHelpSheet(
                    context,
                    title: 'Desafio',
                    subtitle: 'Prazo, meta e ranking da campanha.',
                    tips: [
                      const FxHelpTip(
                        'Ranking',
                        'Soma hábitos ou treinos até a meta. Toque no aluno para abrir a ficha.',
                      ),
                      FxHelpTip(
                        widget.forAluno ? 'Pontuar' : 'Encerrar',
                        widget.forAluno
                            ? 'O botão leva ao hábito ou ao treino que pontua.'
                            : 'Encerrar tira a campanha da lista ativa.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: _loading && desafio == null
                ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                : _erro != null && desafio == null
                ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: 'Não conseguimos carregar o desafio',
                    message: _erro!,
                    onRetry: _load,
                  )
                : desafio == null
                ? FxEmptyState(
                    icon: 'spark',
                    title: 'Desafio não encontrado',
                    subtitle:
                        'Ele pode ter sido encerrado. Volte à lista e escolha outro.',
                    action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                  )
                : _DesafioDetailBody(
                    desafio: desafio,
                    ranking: _ranking,
                    forAluno: widget.forAluno,
                    meId: meId,
                    secao: _secao,
                    encerrando: _encerrando,
                    onSecao: (value) => setState(() => _secao = value),
                    onRefresh: _load,
                    onEncerrar: _encerrar,
                    onAlunoSticky: _alunoSticky,
                    onLeave: _leave,
                  ),
          ),
        ),
      ),
    );
  }
}

class _DesafioDetailBody extends StatelessWidget {
  const _DesafioDetailBody({
    required this.desafio,
    required this.ranking,
    required this.forAluno,
    required this.meId,
    required this.secao,
    required this.encerrando,
    required this.onSecao,
    required this.onRefresh,
    required this.onEncerrar,
    required this.onAlunoSticky,
    required this.onLeave,
  });

  final Desafio desafio;
  final List<DesafioLeaderboardEntry> ranking;
  final bool forAluno;
  final int? meId;
  final String secao;
  final bool encerrando;
  final ValueChanged<String> onSecao;
  final Future<void> Function() onRefresh;
  final VoidCallback onEncerrar;
  final VoidCallback onAlunoSticky;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final descricao = desafio.descricao?.trim();
    final first = ranking.isEmpty ? null : ranking.first;
    final atingiram = desafioAtingiramMeta(
      ranking.map((e) => e.pontos),
      desafio.metaPontos,
    );
    final meuIndex = desafioMeuIndex(
      ranking.map((e) => e.alunoId),
      meId,
    );
    final meusPontos =
        meuIndex == null ? 0 : ranking[meuIndex].pontos;

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
                    title: desafio.titulo,
                    subtitle: desafioDetailSubtitle(
                      tipo: desafio.tipo,
                      fim: desafio.fim,
                    ),
                  ),
                  if (forAluno) ...[
                    const SizedBox(height: TokensStrip.s4),
                    FxStripCard(
                      emphasize: false,
                      accent: primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sua posição',
                            style: FocuxHubTypography.chip(
                              fxScreenMute(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desafioMeuLugarValue(meuIndex),
                            style: FocuxHubTypography.kpi(
                              color: fxScreenInk(context),
                              fontSize: FocuxHubTypography.metricLg,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desafioMeuLugarHint(
                              index: meuIndex,
                              pontos: meusPontos,
                              metaPontos: desafio.metaPontos,
                            ),
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s4),
                  OperationalMetricTile(
                    label: 'Prazo',
                    value: desafioDiasRestantesValue(desafio.fim),
                    hint: desafioDiasRestantesHint(desafio.fim),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Participantes',
                    value: desafioParticipantesValue(ranking.length),
                    hint: desafioParticipantesHint(ranking.length),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Meta',
                    value: desafioMetaAtingidaValue(
                      atingiram: atingiram,
                      total: ranking.length,
                    ),
                    hint: desafioMetaAtingidaHint(desafio.metaPontos),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: forAluno ? 'Pontos' : 'Tipo',
                    value: forAluno
                        ? desafioLeaderboardPoints(meusPontos)
                        : desafioTipoLabel(desafio.tipo),
                    hint: desafioMetaLabel(desafio.metaPontos),
                    color: primary,
                    isDark: isDark,
                  ),
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
                      if (!forAluno &&
                          first != null &&
                          first.alunoId > 0)
                        DashboardHomeActionChip(
                          label: '1º lugar',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () =>
                              context.push('/alunos/${first.alunoId}'),
                        ),
                      if (!forAluno && desafio.grupoAulaId != null)
                        DashboardHomeActionChip(
                          label: 'Turma',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => context.push('/grupo-aulas'),
                        ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  AlunoSegmentedChoice(
                    options: desafioDetalheSecoes,
                    selected: secao,
                    isDark: isDark,
                    onSelect: onSecao,
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (secao == desafioSecaoCampanha)
                    (descricao == null || descricao.isEmpty)
                        ? (forAluno
                            ? FxEmptyState(
                                icon: 'spark',
                                title: desafioCampanhaEmpty(),
                                subtitle:
                                    'Prazo e meta continuam nos números acima.',
                                action: FxEmptyAction(
                                  label: desafioStickyAlunoLabel(desafio.tipo),
                                  onTap: onAlunoSticky,
                                ),
                              )
                            : Text(
                                desafioCampanhaEmpty(),
                                style: FocuxHubTypography.bodyMuted(
                                  color: fxScreenMute(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                        : Text(
                            descricao,
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                  else if (ranking.isEmpty)
                    FxEmptyState(
                      icon: 'spark',
                      title: desafioLeaderboardEmpty(),
                      subtitle: 'Quando alguém pontuar, o lugar aparece aqui.',
                      action: forAluno
                          ? FxEmptyAction(
                              label: desafioStickyAlunoLabel(desafio.tipo),
                              onTap: onAlunoSticky,
                            )
                          : FxEmptyAction(
                              label: 'Atualizar',
                              onTap: () => onRefresh(),
                            ),
                    )
                  else
                    for (var i = 0; i < ranking.length; i++)
                      FxSatelliteListTile(
                        title: desafioLeaderboardTitle(
                          nome: ranking[i].alunoNome,
                          isSelf: forAluno &&
                              meId != null &&
                              ranking[i].alunoId == meId,
                        ),
                        subtitle: Text(desafioLugarLabel(i)),
                        trailing: Text(
                          desafioLeaderboardPoints(ranking[i].pontos),
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        accent: forAluno &&
                                meId != null &&
                                ranking[i].alunoId == meId
                            ? primary
                            : null,
                        onTap: forAluno || ranking[i].alunoId <= 0
                            ? null
                            : () => context.push(
                                '/alunos/${ranking[i].alunoId}',
                              ),
                      ),
                ],
              ),
            ),
          ),
        ),
        if (forAluno || desafio.ativo)
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
                    ? desafioStickyAlunoLabel(desafio.tipo)
                    : desafioStickyEncerrarLabel(),
                loading: encerrando,
                onPressed: forAluno
                    ? onAlunoSticky
                    : (encerrando ? null : onEncerrar),
              ),
            ),
          ),
      ],
    );
  }
}

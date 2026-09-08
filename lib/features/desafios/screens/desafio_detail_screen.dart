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
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
      final ranking = await _repo.leaderboard(widget.desafioId);
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
            appBar: FxShellAppBar(
              title: 'Desafio',
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
                    freshness: FxHubFreshness.fromFetchedAt(_fetchedAt),
                    forAluno: widget.forAluno,
                    encerrando: _encerrando,
                    onRefresh: _load,
                    onEncerrar: _encerrar,
                    onAlunoSticky: _alunoSticky,
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
    required this.freshness,
    required this.forAluno,
    required this.encerrando,
    required this.onRefresh,
    required this.onEncerrar,
    required this.onAlunoSticky,
  });

  final Desafio desafio;
  final List<DesafioLeaderboardEntry> ranking;
  final String? freshness;
  final bool forAluno;
  final bool encerrando;
  final Future<void> Function() onRefresh;
  final VoidCallback onEncerrar;
  final VoidCallback onAlunoSticky;

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
                      freshness: freshness,
                    ),
                  ),
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
                    label: 'Tipo',
                    value: desafioTipoLabel(desafio.tipo),
                    hint: desafioMetaLabel(desafio.metaPontos),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
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
                  if (descricao != null && descricao.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s4),
                    Text(
                      descricao,
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s4),
                  if (ranking.isEmpty)
                    FxEmptyState(
                      icon: 'spark',
                      title: desafioLeaderboardEmpty(),
                      subtitle: 'Quando alguém pontuar, o lugar aparece aqui.',
                    )
                  else
                    for (var i = 0; i < ranking.length; i++)
                      FxSatelliteListTile(
                        title: desafioLeaderboardName(ranking[i].alunoNome),
                        subtitle: Text(desafioLugarLabel(i)),
                        trailing: Text(
                          desafioLeaderboardPoints(ranking[i].pontos),
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

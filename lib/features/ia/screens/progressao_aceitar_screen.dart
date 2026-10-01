import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/alunos/widgets/aluno_avatar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../treinos/providers/treinos_provider.dart';
import '../data/ia_repository.dart';
import '../models/progressao_sugestao.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../utils/progressao_copy.dart';
import '../widgets/ia_progressao_card_entrance.dart';
import '../widgets/ia_progressao_exercise_card.dart';

class ProgressaoAceitarScreen extends ConsumerStatefulWidget {
  const ProgressaoAceitarScreen({super.key});

  @override
  ConsumerState<ProgressaoAceitarScreen> createState() =>
      _ProgressaoAceitarScreenState();
}

class _ProgressaoAceitarScreenState
    extends ConsumerState<ProgressaoAceitarScreen> {
  int? _actingOnId;
  bool _aceitandoTodas = false;
  String? _successBanner;

  bool get _busy => _actingOnId != null || _aceitandoTodas;

  void _refreshAfterApply(int? alunoId) {
    ref.invalidate(progressaoSugestoesProvider(alunoId));
    if (alunoId != null) {
      ref.invalidate(treinosDoAlunoPageProvider(alunoId));
    }
  }

  void _abrirTreinos(ProgressaoAceitarRouteArgs args, int alunoId) {
    context.push(
      '/alunos/$alunoId/treinos-list',
      extra: args.alunoNome ?? 'Aluno',
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ProgressaoAceitarRouteArgs.resolve(context);
    final sugestoesAsync = ref.watch(progressaoSugestoesProvider(args.alunoId));
    final firstName = satelliteFirstName(args.alunoNome, fallback: 'aluno');
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Sugestões pendentes de progressão',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Sugestões pendentes',
          subtitle: args.alunoNome,
          onBack: () => safePopOrGo(context, args.returnTo ?? '/ia/copiloto'),
          actions: [
            Semantics(
              button: true,
              enabled: !_busy,
              label: 'Atualizar sugestões pendentes',
              child: IconButton(
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed:
                    _busy
                        ? null
                        : () => ref.invalidate(
                          progressaoSugestoesProvider(args.alunoId),
                        ),
              ),
            ),
          ],
        ),
        body: sugestoesAsync.when(
          loading: () => const SkeletonList(count: 4),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                title: 'Não carregou as sugestões',
                message: friendlyError(
                  e,
                  fallback:
                      'Tente novamente. Se o problema continuar, volte ao aluno e gere uma nova progressão.',
                ),
                onRetry:
                    () => ref.invalidate(
                      progressaoSugestoesProvider(args.alunoId),
                    ),
              ),
          data: (bruta) {
            if (bruta.isEmpty) return _empty(args, firstName);

            final alunoId = args.alunoId;
            final lista = [
              ...bruta.where((s) => !s.naoEncontrada),
              ...bruta.where((s) => s.naoEncontrada),
            ];
            final pendentes = lista.where((s) => !s.naoEncontrada).length;
            final fora = lista.length - pendentes;
            return Aluno360Layout.operacaoContentWidthLimiter(
              child: ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  if (_successBanner != null) ...[
                    _SuccessBanner(message: _successBanner!),
                    const SizedBox(height: TokensStrip.s3),
                  ],
                  if (alunoId != null) ...[
                    _AlunoHeader(
                      nome: args.alunoNome ?? lista.first.alunoNome ?? 'Aluno',
                      fotoUrl: args.alunoFotoUrl,
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    if (pendentes > 0) ...[
                      Semantics(
                        button: true,
                        enabled: !_busy,
                        label: progressaoAceitarTodasLabel(pendentes),
                        child: FilledButton.icon(
                          onPressed:
                              _busy
                                  ? null
                                  : () => _aceitarTodas(args, alunoId, pendentes),
                          icon:
                              _aceitandoTodas
                                  ? FxLoading(
                                    size: 18,
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                  : const Icon(Icons.done_all_rounded, size: 18),
                          label: Text(progressaoAceitarTodasLabel(pendentes)),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                    ],
                    if (fora > 0) ...[
                      _ForaDoTreinoPanel(
                        count: fora,
                        busy: _busy,
                        onRetry: () => _aplicarTodas(alunoId),
                        onDiscard: () => _descartarFora(alunoId, fora),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                    ],
                  ],
                  for (final (i, sugestao) in lista.indexed)
                    IaProgressaoCardEntrance(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                        child: _card(args, sugestao, primary),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(ProgressaoAceitarRouteArgs args, String firstName) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s4),
      children: [
        if (_successBanner != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
            child: _SuccessBanner(message: _successBanner!),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        FxEmptyState(
          icon: 'circle-check',
          title:
              _successBanner != null ? 'Tudo em dia' : 'Nenhuma sugestão pendente',
          subtitle:
              args.alunoId == null
                  ? 'Quando a IA sugerir progressão de carga, ela aparecerá aqui para você revisar e aplicar.'
                  : _successBanner != null
                  ? 'O treino foi atualizado. Gere uma nova progressão quando quiser.'
                  : 'Gere uma progressão com IA para $firstName e volte aqui para revisar antes de aplicar no treino.',
          action:
              args.alunoId == null
                  ? null
                  : FxEmptyAction(
                    label: 'Gerar progressão com IA',
                    onTap:
                        () => context.push(
                          '/alunos/${args.alunoId}/ia/progressao',
                          extra: args.alunoNome ?? 'Aluno',
                        ),
                  ),
        ),
        if (args.alunoId != null)
          Center(
            child: TextButton.icon(
              onPressed:
                  () => safePopOrGo(
                    context,
                    args.returnTo ?? '/alunos/${args.alunoId}',
                  ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Voltar ao Aluno 360'),
            ),
          ),
      ],
    );
  }

  Widget _card(
    ProgressaoAceitarRouteArgs args,
    ProgressaoSugestao sugestao,
    Color primary,
  ) {
    final busy = _actingOnId == sugestao.id;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
    );
    final rejeitar = Semantics(
      button: true,
      label: 'Rejeitar sugestão de ${sugestao.exercicio}',
      child: OutlinedButton.icon(
        onPressed: _busy ? null : () => _confirmarRejeicao(args, sugestao),
        icon:
            busy && sugestao.naoEncontrada
                ? const FxLoading(size: 18, strokeWidth: 2)
                : const Icon(Icons.close_rounded, size: 18),
        label: Text(sugestao.naoEncontrada ? 'Descartar' : 'Rejeitar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: EagleTokens.bad,
          side: BorderSide(color: EagleTokens.bad.withValues(alpha: 0.55)),
          minimumSize: const Size(48, 48),
          shape: buttonShape,
        ),
      ),
    );

    final Widget acoes;
    if (sugestao.naoEncontrada) {
      acoes = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 16,
                color: EagleTokens.warn,
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Text(
                  '$progressaoNaoEncontrada. $progressaoNaoEncontradaHint',
                  style: FocuxHubTypography.bodyMuted(
                    color: TokensStrip.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(child: rejeitar),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _busy
                          ? null
                          : () => _abrirTreinos(args, sugestao.alunoId),
                  icon: const Icon(Icons.fitness_center_rounded, size: 18),
                  label: const Text(progressaoAbrirTreino),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: buttonShape,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      acoes = Row(
        children: [
          Expanded(child: rejeitar),
          const SizedBox(width: TokensStrip.s3),
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Aceitar sugestão de ${sugestao.exercicio} e aplicar no treino',
              child: FilledButton.icon(
                onPressed:
                    _busy ? null : () => _acao(args, sugestao, aceitar: true),
                icon:
                    busy
                        ? FxLoading(
                          size: 18,
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                        : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Aceitar'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(48, 48),
                  shape: buttonShape,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return IaProgressaoExerciseCard(
      exercicio: sugestao.exercicio,
      cargaAtual: sugestao.cargaAtual,
      cargaSugerida: sugestao.cargaSugerida,
      justificativa: sugestao.justificativa,
      deltaLabel: sugestao.deltaLabel,
      padding: const EdgeInsets.all(TokensStrip.s3),
      header:
          args.alunoId == null
              ? _AlunoHeader(
                nome: sugestao.alunoNome ?? args.alunoNome ?? 'Aluno',
                fotoUrl: args.alunoFotoUrl,
              )
              : null,
      footerActions: acoes,
    );
  }

  Future<void> _aceitarTodas(
    ProgressaoAceitarRouteArgs args,
    int alunoId,
    int pendentes,
  ) async {
    final ok = await showFxConfirmSheet(
      context,
      title: progressaoAceitarTodasLabel(pendentes),
      message: progressaoAceitarTodasConfirm(pendentes),
      icon: Icons.done_all_rounded,
      confirmLabel: 'Aplicar',
    );
    if (!ok || !mounted) return;
    await _aplicarTodas(alunoId);
  }

  Future<void> _aplicarTodas(int alunoId) async {
    if (_busy) return;
    setState(() => _aceitandoTodas = true);
    try {
      final r = await IaRepository(
        ref.read(apiClientProvider),
      ).aceitarTodasSugestoes(alunoId);
      _refreshAfterApply(alunoId);
      if (!mounted) return;
      final msg = progressaoAceitarTodasSnack(r);
      if (r.aplicadas > 0) {
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _successBanner = msg);
        FeedbackHelper.showSuccess(context, msg);
      } else {
        setState(() => _successBanner = null);
        FeedbackHelper.showInfo(context, msg);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível aplicar as sugestões.'),
        );
      }
    } finally {
      if (mounted) setState(() => _aceitandoTodas = false);
    }
  }

  Future<void> _descartarFora(int alunoId, int count) async {
    final ok = await showFxConfirmSheet(
      context,
      title: progressaoDescartarTodas,
      message: progressaoDescartarForaConfirm(count),
      icon: Icons.delete_sweep_rounded,
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _aceitandoTodas = true);
    try {
      final n = await IaRepository(
        ref.read(apiClientProvider),
      ).descartarSugestoesNaoEncontradas(alunoId);
      ref.invalidate(progressaoSugestoesProvider(alunoId));
      if (mounted) {
        FeedbackHelper.showSuccess(context, progressaoDescartadasSnack(n));
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível descartar as sugestões.'),
        );
      }
    } finally {
      if (mounted) setState(() => _aceitandoTodas = false);
    }
  }

  Future<void> _confirmarRejeicao(
    ProgressaoAceitarRouteArgs args,
    ProgressaoSugestao sugestao,
  ) async {
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Descartar sugestão?',
      message:
          'A sugestão de ${sugestao.exercicio} (${sugestao.cargaSugerida}) será removida.',
      icon: Icons.delete_sweep_rounded,
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (confirmed && mounted) {
      await _acao(args, sugestao, aceitar: false);
    }
  }

  Future<void> _acao(
    ProgressaoAceitarRouteArgs args,
    ProgressaoSugestao sugestao, {
    required bool aceitar,
  }) async {
    setState(() => _actingOnId = sugestao.id);
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      if (aceitar) {
        final response = await repo.aceitarSugestao(sugestao.id);
        _refreshAfterApply(args.alunoId ?? sugestao.alunoId);
        ref.invalidate(progressaoSugestoesProvider(args.alunoId));
        if (!mounted) return;
        unawaited(HapticFeedback.mediumImpact());
        if (response.cargaAplicada) {
          setState(() => _successBanner = response.mensagem);
          FeedbackHelper.showSuccess(context, response.mensagem);
        } else {
          FeedbackHelper.showInfo(context, response.mensagem);
        }
      } else {
        await repo.rejeitarSugestao(sugestao.id);
        ref.invalidate(progressaoSugestoesProvider(args.alunoId));
        if (mounted) {
          FeedbackHelper.showSuccess(context, 'Sugestão descartada.');
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível concluir a progressão.'),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }
}

class _AlunoHeader extends StatelessWidget {
  const _AlunoHeader({required this.nome, this.fotoUrl});

  final String nome;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AlunoAvatar(
          name: nome,
          photoUrl: fotoUrl,
          variant: AlunoAvatarVariant.strip,
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: Text(
            nome,
            style: FocuxHubTypography.body(
              color: ShellChrome.of(context).ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ForaDoTreinoPanel extends StatelessWidget {
  const _ForaDoTreinoPanel({
    required this.count,
    required this.busy,
    required this.onRetry,
    required this.onDiscard,
  });

  final int count;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: BoxDecoration(
        color: EagleTokens.warn.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: EagleTokens.warn.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.search_off_rounded, size: 18, color: EagleTokens.warn),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Text(
                  progressaoForaDoTreinoResumo(count),
                  style: FocuxHubTypography.body(
                    color: ShellChrome.of(context).ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onDiscard,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text(progressaoDescartarTodas),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EagleTokens.bad,
                    side: BorderSide(color: EagleTokens.bad.withValues(alpha: 0.55)),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(progressaoTentarDeNovo),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EagleTokens.good.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: EagleTokens.good.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: EagleTokens.good, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

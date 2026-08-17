import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
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
import '../data/ia_repository.dart';
import '../models/progressao_sugestao.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_aceitar_route_args.dart';
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
  String? _successBanner;

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
              label: 'Atualizar sugestões pendentes',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    _actingOnId == null
                        ? () => ref.invalidate(
                          progressaoSugestoesProvider(args.alunoId),
                        )
                        : null,
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
          data: (lista) {
            if (lista.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: TokensStrip.s4),
                children: [
                  if (_successBanner != null) ...[
                    _SuccessBanner(message: _successBanner!),
                    const SizedBox(height: TokensStrip.s2),
                  ],
                  FxEmptyState(
                    icon: 'circle-check',
                    title:
                        _successBanner != null
                            ? 'Tudo em dia'
                            : 'Nenhuma sugestão pendente',
                    subtitle:
                        args.alunoId == null
                            ? 'Quando a IA sugerir progressão de carga, ela aparecerá aqui para você revisar e aplicar.'
                            : _successBanner != null
                            ? 'A carga foi registrada. Gere uma nova progressão quando quiser atualizar o plano.'
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

            return Aluno360Layout.operacaoContentWidthLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(TokensStrip.s4),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final sugestao = lista[i];
                  final busy = _actingOnId == sugestao.id;
                  return IaProgressaoCardEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: IaProgressaoExerciseCard(
                        exercicio: sugestao.exercicio,
                        cargaAtual: sugestao.cargaAtual,
                        cargaSugerida: sugestao.cargaSugerida,
                        justificativa: sugestao.justificativa,
                        deltaLabel: sugestao.deltaLabel,
                        padding: const EdgeInsets.all(TokensStrip.s4),
                        header: Row(
                          children: [
                            AlunoAvatar(
                              name:
                                  sugestao.alunoNome ??
                                  args.alunoNome ??
                                  'Aluno',
                              photoUrl: args.alunoFotoUrl,
                              variant: AlunoAvatarVariant.strip,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sugestao.alunoNome ??
                                    args.alunoNome ??
                                    'Aluno',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: chrome.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        footerActions: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                button: true,
                                label:
                                    'Rejeitar sugestão de ${sugestao.exercicio}',
                                child: OutlinedButton.icon(
                                  onPressed:
                                      busy
                                          ? null
                                          : () => _confirmarRejeicao(
                                            args,
                                            sugestao,
                                          ),
                                  icon:
                                      busy
                                          ? const FxLoading(
                                            size: 18,
                                            strokeWidth: 2,
                                          )
                                          : const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                  label: const Text('Rejeitar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: EagleTokens.bad,
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Semantics(
                                button: true,
                                label:
                                    'Aceitar sugestão de ${sugestao.exercicio} e aplicar no treino',
                                child: FilledButton.icon(
                                  onPressed:
                                      busy
                                          ? null
                                          : () => _acao(
                                            args,
                                            sugestao,
                                            aceitar: true,
                                          ),
                                  icon:
                                      busy
                                          ? const FxLoading(
                                            size: 18,
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          )
                                          : const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                          ),
                                  label: const Text('Aceitar'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: EagleTokens.good,
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmarRejeicao(
    ProgressaoAceitarRouteArgs args,
    ProgressaoSugestao sugestao,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Descartar sugestão?'),
            content: Text(
              'A sugestão de ${sugestao.exercicio} (${sugestao.cargaSugerida}) será removida.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) {
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
        ref.invalidate(progressaoSugestoesProvider(args.alunoId));
        if (!mounted) return;
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _successBanner = response.mensagem);
        FeedbackHelper.showSuccess(context, response.mensagem);
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

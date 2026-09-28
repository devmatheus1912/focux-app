import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/aluno360_client_cache.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../models/treino_previa.dart';
import '../providers/checkin_provider.dart';
import '../utils/treino_previa_view.dart';
import '../widgets/treino_previa_widgets.dart';

/// Prescrição antes de treinar. Só o botão Iniciar abre sessão; ao iniciar a
/// tela fecha com `true` e quem abriu leva à execução.
class TreinoPreviaScreen extends ConsumerStatefulWidget {
  const TreinoPreviaScreen({super.key, required this.treinoId});

  final int treinoId;

  @override
  ConsumerState<TreinoPreviaScreen> createState() => _TreinoPreviaScreenState();
}

class _TreinoPreviaScreenState extends ConsumerState<TreinoPreviaScreen> {
  var _registrando = false;
  var _homeRecarregadaPor404 = false;

  void _voltar() => safePopOrGo(context, '/checkin/treinos');

  void _iniciar() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.pushReplacement('/checkin/executar', extra: widget.treinoId);
    }
  }

  Future<void> _jaFiz() async {
    if (_registrando) return;
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.treinoJaFizConfirmTitulo,
      message: s.treinoJaFizConfirmMensagem,
      confirmLabel: s.treinoJaFizConfirmar,
      cancelLabel: s.treinoJaFizVoltar,
      icon: Icons.check_circle_outline_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _registrando = true);
    try {
      await ref.read(checkinRepositoryProvider).confirmarPlano(widget.treinoId);
      EvolucaoHomeClientCache.clear();
      Aluno360ClientCache.clear();
      invalidateAlunoDashboardHome(ref);
      if (!mounted) return;
      await FxCelebrationOverlay.show(
        context,
        title: s.treinoJaFizSucessoTitulo,
        subtitle: s.treinoJaFizSucessoSubtitulo,
        icon: Icons.check_circle_rounded,
      );
      if (mounted) _voltar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
      setState(() => _registrando = false);
    }
  }

  /// Ficha fora do plano: o agregado da Home também está velho.
  void _recarregarHomeUmaVez() {
    if (_homeRecarregadaPor404) return;
    _homeRecarregadaPor404 = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) invalidateAlunoDashboardHome(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final previaAsync = ref.watch(treinoPreviaProvider(widget.treinoId));
    final home = ref.watch(alunoDashboardHomeProvider).value;
    final now = DateTime.now();
    final previa = previaAsync.value;

    return fxScreenA11yScope(
      label: previa?.treinoNome ?? s.treinosHubTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: previa?.treinoNome ?? s.treinosHubTitulo,
          onBack: _voltar,
        ),
        body: previaAsync.when(
          skipLoadingOnReload: true,
          loading: () => const _PreviaSkeleton(),
          error: (e, _) {
            if (e is DioException && e.response?.statusCode == 404) {
              _recarregarHomeUmaVez();
              return FxContentWidthLimiter(
                child: FxEmptyState(
                  icon: 'dumbbell',
                  title: s.treinoPreviaNaoEncontrado,
                  action: FxEmptyAction(
                    label: s.treinoPreviaVoltar,
                    onTap: _voltar,
                  ),
                ),
              );
            }
            return FxContentWidthLimiter(
              child: FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry:
                    () => ref.invalidate(treinoPreviaProvider(widget.treinoId)),
              ),
            );
          },
          data:
              (p) => _PreviaBody(
                previa: p,
                hoje: now,
                situacao:
                    home == null
                        ? null
                        : treinoPreviaSituacao(
                          treinoId: widget.treinoId,
                          treinos: home.treinos,
                          historico: home.historico,
                          now: now,
                        ),
                registrando: _registrando,
                onIniciar: _iniciar,
                onJaFiz: _jaFiz,
              ),
        ),
      ),
    );
  }
}

class _PreviaBody extends StatelessWidget {
  const _PreviaBody({
    required this.previa,
    required this.hoje,
    required this.situacao,
    required this.registrando,
    required this.onIniciar,
    required this.onJaFiz,
  });

  final TreinoPrevia previa;
  final DateTime hoje;
  final TreinoPreviaSituacao? situacao;
  final bool registrando;
  final VoidCallback onIniciar;
  final VoidCallback onJaFiz;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final podeTreinar =
        previa.exercicios.isNotEmpty &&
        situacao != TreinoPreviaSituacao.emPreparacao;
    final continuar = situacao == TreinoPreviaSituacao.emAndamento;

    return Column(
      children: [
        Expanded(
          child: FxContentWidthLimiter(
            child: ListView(
              padding: const EdgeInsets.all(TokensStrip.s4),
              children: [
                TreinoPreviaCabecalho(
                  texto: treinoPreviaCabecalho(s, previa, hoje: hoje),
                ),
                const SizedBox(height: TokensStrip.s3),
                for (final (i, e) in previa.exercicios.indexed) ...[
                  if (i > 0) const SizedBox(height: TokensStrip.s2),
                  TreinoPreviaExercicioTile(numero: i + 1, exercicio: e),
                ],
              ],
            ),
          ),
        ),
        if (podeTreinar)
          SafeArea(
            top: false,
            child: FxContentWidthLimiter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s1,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxLiquidPrimaryButton(
                      label:
                          continuar
                              ? s.treinosContinuarCta
                              : s.treinosIniciarCta,
                      icon: Icons.play_arrow_rounded,
                      onPressed: registrando ? null : onIniciar,
                    ),
                    if (treinoPreviaMostraJaFiz(situacao)) ...[
                      const SizedBox(height: TokensStrip.s1),
                      TextButton(
                        onPressed: registrando ? null : onJaFiz,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(s.treinoJaFizCta),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviaSkeleton extends StatelessWidget {
  const _PreviaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: S.of(context).treinoPreviaCarregando,
      excludeSemantics: true,
      child: const FxContentWidthLimiter(
        child: Padding(
          padding: EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 180, height: 16),
              SizedBox(height: TokensStrip.s3),
              SkeletonLoader(height: 72, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s2),
              SkeletonLoader(height: 72, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s2),
              SkeletonLoader(height: 72, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}

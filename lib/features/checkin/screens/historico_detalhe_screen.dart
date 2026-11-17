import 'package:dio/dio.dart';
import '../../../core/navigation/fx_abertura_unica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_async_body.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/checkin_repository.dart';
import '../providers/historico_provider.dart';
import '../utils/historico_detalhe_texts.dart';
import '../utils/historico_detalhe_view.dart';
import '../utils/treinos_hub_view.dart';
import '../widgets/historico_detalhe_widgets.dart';
import '../../../core/theme/fx_icons.dart';

/// Uma sessão do histórico. Concluída: "Treinar de novo" abre a prévia.
/// Aberta (link antigo ou push): "Continuar treino".
class HistoricoDetalheScreen extends ConsumerStatefulWidget {
  const HistoricoDetalheScreen({
    super.key,
    required this.execucaoId,
    this.alunoIdDoPersonal,
  });

  final int execucaoId;

  /// Aberto pelo personal (linha do tempo do 360): só leitura, sem
  /// "Treinar de novo", e volta para o aluno.
  final int? alunoIdDoPersonal;

  bool get doPersonal => alunoIdDoPersonal != null;

  @override
  ConsumerState<HistoricoDetalheScreen> createState() =>
      _HistoricoDetalheScreenState();
}

class _HistoricoDetalheScreenState
    extends ConsumerState<HistoricoDetalheScreen> {
  final _abertura = FxAberturaUnica();

  void _voltar() => widget.doPersonal
      ? safePopOrGo(context, '/alunos/${widget.alunoIdDoPersonal}')
      : safePopOrGo(context, '/checkin/historico');

  ProviderListenable<AsyncValue<ExecucaoTreino>> get _detalhe =>
      widget.doPersonal
          ? historicoDetalhePersonalProvider(widget.execucaoId)
          : historicoDetalheProvider(widget.execucaoId);

  // Treinar de novo e continuar mudam a Home, a lista e esta sessão: ao
  // voltar, o `AtualizaAoVoltarScope` relê (o retorno pode nunca chegar).
  void _treinarDeNovo(int treinoId) {
    _abertura.abrir(() => context.push<bool>(treinoPreviaPath(treinoId)));
  }

  void _continuar(int treinoId) {
    _abertura.abrir(
      () => context.push<Object?>(checkinExecutarPath(treinoId)),
    );
  }

  Future<void> _refresh() async {
    final s = S.of(context);
    ref
      ..invalidate(historicoEvolucaoProvider(widget.execucaoId))
      ..invalidate(historicoDetalheProvider(widget.execucaoId));
    try {
      await ref.read(historicoDetalheProvider(widget.execucaoId).future);
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, s.historicoAtualizarErro);
      return;
    }
    if (mounted) fxAnnounce(context, s.historicoDetalheAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final detalheAsync = ref.watch(_detalhe);
    final evolucao =
        ref
            .watch(
              widget.doPersonal
                  ? historicoEvolucaoPersonalProvider(widget.execucaoId)
                  : historicoEvolucaoProvider(widget.execucaoId),
            )
            .value;
    final execucao = detalheAsync.value;
    final view =
        execucao == null
            ? null
            : buildHistoricoDetalheView(execucao, evolucao: evolucao);
    // O personal não tem a Home do aluno: nada de "Treinar de novo".
    final noPlano =
        !widget.doPersonal &&
        (ref
                .watch(alunoDashboardHomeProvider)
                .value
                ?.treinos
                .any((t) => t.treinoId == execucao?.treinoId) ??
            false);
    final titulo = execucao?.treinoNome ?? s.historicoTitulo;
    final naoEncontrada =
        !detalheAsync.hasValue &&
        detalheAsync.error is DioException &&
        (detalheAsync.error! as DioException).response?.statusCode == 404;

    return fxScreenA11yScope(
      label: titulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: titulo,
          subtitle: view == null ? null : historicoDetalheSubtitulo(s, view),
          onBack: _voltar,
        ),
        body:
            naoEncontrada
                ? FxContentWidthLimiter(
                  child: FxEmptyState(
                    icon: FxIcons.treino,
                    title: s.historicoDetalheNaoEncontrado,
                    action: FxEmptyAction(
                      label: s.historicoDetalheVoltar,
                      onTap: _voltar,
                    ),
                  ),
                )
                : FxAsyncBody<ExecucaoTreino>(
                  value: detalheAsync,
                  skipLoadingOnReload: true,
                  skipError: true,
                  skeleton: const HistoricoDetalheSkeleton(),
                  onRetry:
                      () => ref.invalidate(
                        historicoDetalheProvider(widget.execucaoId),
                      ),
                  builder:
                      (context, e) => _corpo(
                        context,
                        e,
                        view ?? buildHistoricoDetalheView(e),
                        noPlano: noPlano,
                      ),
                ),
      ),
    );
  }

  Widget _corpo(
    BuildContext context,
    ExecucaoTreino execucao,
    HistoricoDetalheView v, {
    required bool noPlano,
  }) {
    final s = S.of(context);
    final cta = switch ((v.concluida, noPlano)) {
      (true, true) => (
        s.historicoTreinarDeNovo,
        () => _treinarDeNovo(execucao.treinoId),
      ),
      (false, _) when !widget.doPersonal => (
        s.treinosContinuarCta,
        () => _continuar(execucao.treinoId),
      ),
      _ => null,
    };

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  HistoricoResumoCard(view: v),
                  const SizedBox(height: TokensStrip.s3),
                  HistoricoMetricas(view: v),
                  if (v.recordes.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s4),
                    HistoricoSecao(
                      titulo: s.historicoRecordes,
                      filhos: [
                        for (final g in historicoRecordesPorExercicio(
                          v.recordes,
                          nomesDaLista: [for (final e in v.exercicios) e.nome],
                        ))
                          HistoricoInfoTile(
                            titulo: g.exercicio,
                            detalhe: g.linhas.join('\n'),
                            icone: FxIcons.trofeu,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s4),
                  HistoricoSecao(
                    titulo: s.historicoExercicios,
                    filhos: [
                      if (v.exercicios.isEmpty)
                        Text(
                          s.historicoSemExercicios,
                          style: FocuxHubTypography.bodyMuted(
                            color: ShellChrome.of(context).mute,
                          ),
                        )
                      else
                        HistoricoGrupo(
                          filhos: [
                            for (final l in v.exercicios)
                              HistoricoExercicioTile(linha: l),
                          ],
                        ),
                    ],
                  ),
                  if (v.orientacaoGeral case final orientacao?) ...[
                    const SizedBox(height: TokensStrip.s4),
                    HistoricoOrientacao(texto: orientacao),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (cta case (final label, final onPressed))
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
                child: FxLiquidPrimaryButton(
                  label: label,
                  icon: FxIcons.play,
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

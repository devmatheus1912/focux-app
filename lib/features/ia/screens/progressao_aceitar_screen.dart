import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:printing/printing.dart';

import '../../../core/pdf/focux_pdf_brand_loader.dart';
import '../../../core/pdf/focux_pdf_kit.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_number_pad_sheet.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/pt.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../moderacao/data/moderacao_repository.dart';
import '../../moderacao/widgets/denunciar_sheet.dart';
import '../../treinos/providers/treinos_provider.dart';
import '../data/ia_repository.dart';
import '../models/ia_progressao_carga_result.dart';
import '../models/progressao_sugestao.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../utils/progressao_pdf_builder.dart';
import '../widgets/progressao_revisao_linha.dart';
import '../utils/progressao_copy.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_strip_card.dart';

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
  bool _exportando = false;
  String? _successBanner;

  /// Marcação que difere do padrão: "com mudança" nasce marcada.
  final _alternadas = <int>{};
  final _cargas = <int, double>{};
  final _abertas = <int>{};

  bool get _busy => _actingOnId != null || _aceitandoTodas;

  bool _selecionada(ProgressaoSugestao s) =>
      progressaoMudaCarga(s) != _alternadas.contains(s.id);

  void _refreshAfterApply(int? alunoId) {
    ref.invalidate(progressaoSugestoesProvider(alunoId));
    if (alunoId != null) {
      ref.invalidate(treinosDoAlunoPageProvider(alunoId));
    }
  }

  IaProgressaoCargaResult _resultado(List<ProgressaoSugestao> lista) {
    return IaProgressaoCargaResult(
      resposta: '',
      geradoEm: lista.isEmpty ? null : lista.first.criadoEm,
      exercises: [
        for (final s in lista)
          IaProgressaoExerciseRow(
            exercicio: s.exercicio,
            cargaAtual: s.cargaAtual,
            cargaSugerida: s.cargaSugerida,
            justificativa: s.justificativa ?? '',
            deltaLabel: s.deltaLabel,
            treinoExercicioId: s.treinoExercicioId,
          ),
      ],
    );
  }

  Future<void> _maisOpcoes(
    ProgressaoAceitarRouteArgs args,
    List<ProgressaoSugestao> lista,
  ) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.cargasMais,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'copiar',
            rotulo: ptS.cargasCopiar,
            icone: Icons.copy_rounded,
          ),
          FxActionItem(
            valor: 'pdf',
            rotulo: ptS.cargasPdf,
            icone: Icons.picture_as_pdf_outlined,
          ),
          FxActionItem(
            valor: 'denunciar',
            rotulo: ptS.cargasDenunciar,
            icone: Icons.flag_outlined,
          ),
        ]),
      ],
    );
    if (escolha == null || !mounted) return;
    final nome = args.alunoNome ?? 'Aluno';
    final resultado = _resultado(lista);
    switch (escolha) {
      case 'copiar':
        await Clipboard.setData(
          ClipboardData(text: resultado.toPlainText(alunoNome: nome)),
        );
        if (mounted) FeedbackHelper.showSuccess(context, ptS.cargasCopiado);
      case 'pdf':
        await _exportarPdf(resultado, nome);
      case 'denunciar':
        await showDenunciarSheet(
          context,
          repo: ModeracaoRepository(ref.read(apiClientProvider)),
          tipo: DenunciaTipo.iaResposta,
          conteudo: resultado.toPlainText(alunoNome: nome),
        );
    }
  }

  Future<void> _exportarPdf(
    IaProgressaoCargaResult resultado,
    String nome,
  ) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final agora = resultado.geradoEm ?? DateTime.now();
      final bytes = await buildProgressaoPdf(
        result: resultado,
        alunoNome: nome,
        personalNome: ref.read(personalNameProvider),
        assets: await FocuxPdfAssets.load(),
        brand: await carregarMarcaDoPdf(ref),
        agora: agora,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: progressaoPdfFileName(nome, agora),
      );
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não consegui gerar o PDF agora.'),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _editarCarga(ProgressaoSugestao s) async {
    final r = await showFxNumberPadSheet(
      context,
      titulo: s.exercicio,
      confirmarLabel: ptS.cargasConfirmarCarga,
      sufixo: 'kg',
      inicial: _cargas[s.id] ?? s.cargaSugeridaKg,
    );
    final valor = r?.valor;
    if (valor == null || valor <= 0 || !mounted) return;
    setState(() {
      _cargas[s.id] = valor;
      if (!_selecionada(s)) _alternadas.remove(s.id);
      if (!_selecionada(s)) _alternadas.add(s.id);
    });
  }

  Future<void> _aplicarSelecionadas(
    ProgressaoAceitarRouteArgs args,
    List<ProgressaoSugestao> selecionadas,
  ) async {
    if (_busy) return;
    final ok = await showFxConfirmSheet(
      context,
      title: ptS.cargasAplicarConfirmaTitulo,
      message: ptS.cargasAplicarConfirma,
      icon: Icons.done_all_rounded,
      confirmLabel: ptS.cargasAplicarBotao,
    );
    if (!ok || !mounted) return;
    setState(() => _aceitandoTodas = true);
    var aplicadas = 0;
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      for (final s in selecionadas) {
        final r = await repo.aceitarSugestao(s.id, cargaKg: _cargas[s.id]);
        if (r.cargaAplicada) aplicadas++;
      }
      unawaited(HapticFeedback.mediumImpact());
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível aplicar as sugestões.'),
        );
      }
    } finally {
      for (final alunoId in {
        args.alunoId,
        ...selecionadas.map((s) => s.alunoId),
      }) {
        _refreshAfterApply(alunoId);
      }
      ref.invalidate(progressaoSugestoesProvider(args.alunoId));
      if (mounted) {
        setState(() {
          _aceitandoTodas = false;
          _alternadas.clear();
          _cargas.clear();
          if (aplicadas > 0) {
            _successBanner =
                aplicadas == 1
                    ? ptS.cargasAplicadaUma
                    : ptS.cargasAplicadas(aplicadas);
          }
        });
      }
    }
  }

  void _abrirTreinos(ProgressaoAceitarRouteArgs args, int alunoId) {
    context.push('/alunos/$alunoId/rotina', extra: args.alunoNome ?? 'Aluno');
  }

  Widget _grupo(
    ProgressaoAceitarRouteArgs args,
    List<ProgressaoSugestao> sugestoes,
  ) {
    final grupos = progressaoPorTreino(sugestoes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (treino, itens) in grupos) ...[
          if (grupos.length > 1) ...[
            const SizedBox(height: TokensStrip.s2),
            DashboardSectionHeader(title: treino ?? ptS.cargasGrupoOutros),
            const SizedBox(height: TokensStrip.s2),
          ],
          Container(
            decoration: fxListCardDecoration(context),
            child: Column(
              children: [
                for (final (i, s) in itens.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ProgressaoRevisaoLinha(
                    key: ValueKey(s.id),
                    sugestao: s,
                    selecionada: _selecionada(s),
                    aberta: _abertas.contains(s.id),
                    cargaEditada: _cargas[s.id],
                    alunoNome: args.alunoId == null ? s.alunoNome : null,
                    onEditarCarga:
                        s.cargaSugeridaKg == null
                            ? null
                            : () => _editarCarga(s),
                    onSelecionar:
                        (_) => setState(() {
                          if (!_alternadas.remove(s.id)) _alternadas.add(s.id);
                        }),
                    onAbrir:
                        () => setState(() {
                          if (!_abertas.remove(s.id)) _abertas.add(s.id);
                        }),
                    onDescartar: () => _confirmarRejeicao(args, s),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _linhaFora(ProgressaoAceitarRouteArgs args, ProgressaoSugestao s) {
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.exercicio,
              style: FocuxHubTypography.body(color: chrome.ink),
            ),
          ),
          FxTonalButton(
            label: progressaoAbrirTreino,
            compact: true,
            onPressed: _busy ? null : () => _abrirTreinos(args, s.alunoId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ProgressaoAceitarRouteArgs.resolve(context);
    final sugestoesAsync = ref.watch(progressaoSugestoesProvider(args.alunoId));
    final firstName = satelliteFirstName(args.alunoNome, fallback: 'aluno');
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final bruta = sugestoesAsync.value ?? const <ProgressaoSugestao>[];

    return fxScreenA11yScope(
      label: 'Sugestões pendentes de progressão',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: ptS.cargasRevisarTitulo,
          subtitle: args.alunoNome,
          onBack: () => safePopOrGo(context, args.returnTo ?? '/ia/copiloto'),
          actions: [
            FxHelpIconButton(
              tooltip: ptS.cargasComoRevisar,
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: ptS.cargasRevisarTitulo,
                    subtitle: args.alunoNome ?? ptS.cargasComoRevisar,
                    tips: [
                      FxHelpTip(ptS.cargasComoRevisar, ptS.cargasAjudaDiferenca, icon: 'trend'),
                      FxHelpTip(ptS.cargasSoOAplicado, ptS.cargasAjudaSelecao, icon: 'circle-check'),
                      FxHelpTip(ptS.cargasMais, ptS.cargasAjudaEditar, icon: 'spark'),
                    ],
                  ),
            ),
            if (bruta.isNotEmpty)
              IconButton(
                tooltip: ptS.cargasMais,
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: _busy ? null : () => _maisOpcoes(args, bruta),
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
            final ativas = bruta.where((s) => !s.naoEncontrada).toList();
            final fora = bruta.where((s) => s.naoEncontrada).toList();
            final comMudanca = ativas.where(progressaoMudaCarga).toList();
            final semMudanca =
                ativas.where((s) => !progressaoMudaCarga(s)).toList();
            final selecionadas = ativas.where(_selecionada).toList();
            final n = selecionadas.length;
            return Column(
              children: [
                Expanded(
                  child: Aluno360Layout.operacaoContentWidthLimiter(
                    child: ListView(
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      children: [
                        if (_successBanner != null) ...[
                          _SuccessBanner(message: _successBanner!),
                          const SizedBox(height: TokensStrip.s3),
                        ],
                        if (ativas.isNotEmpty) ...[
                          _ResumoDaRevisao(sugestoes: ativas),
                          const SizedBox(height: TokensStrip.s3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ptS.cargasSelecionadasN(n),
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
                                  ),
                                ),
                              ),
                              FxActionLink(
                                label:
                                    n == ativas.length
                                        ? ptS.cargasDesmarcarTodas
                                        : ptS.cargasMarcarTodas,
                                onTap:
                                    () => setState(() {
                                      final marcar = n != ativas.length;
                                      _alternadas
                                        ..clear()
                                        ..addAll([
                                          for (final s in ativas)
                                            if (progressaoMudaCarga(s) != marcar)
                                              s.id,
                                        ]);
                                    }),
                              ),
                            ],
                          ),
                        ],
                        if (comMudanca.isNotEmpty) ...[
                          const SizedBox(height: TokensStrip.s2),
                          _grupo(args, comMudanca),
                        ],
                        if (semMudanca.isNotEmpty) ...[
                          const SizedBox(height: TokensStrip.s3),
                          Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              initiallyExpanded: comMudanca.isEmpty,
                              title: Text(
                                '${ptS.cargasGrupoSemMudanca} · ${semMudanca.length}',
                                style: FocuxHubTypography.cardTitle(
                                  color: chrome.ink,
                                ),
                              ),
                              children: [_grupo(args, semMudanca)],
                            ),
                          ),
                        ],
                        if (fora.isNotEmpty && alunoId != null) ...[
                          const SizedBox(height: TokensStrip.s4),
                          _ForaDoTreinoPanel(
                            count: fora.length,
                            busy: _busy,
                            onRetry: () => _aplicarTodas(alunoId),
                            onDiscard:
                                () => _descartarFora(alunoId, fora.length),
                          ),
                          for (final s in fora) _linhaFora(args, s),
                        ],
                        const SizedBox(height: TokensStrip.s3),
                        IaSafetyDisclaimer(
                          compact: true,
                          customText: ptS.cargasSoOAplicado,
                        ),
                      ],
                    ),
                  ),
                ),
                if (ativas.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s2,
                        TokensStrip.s4,
                        TokensStrip.s3,
                      ),
                      child: FxLiquidPrimaryButton(
                        label: switch (n) {
                          0 => ptS.cargasAplicarNenhuma,
                          1 => ptS.cargasAplicarUma,
                          _ => ptS.cargasAplicar(n),
                        },
                        loading: _aceitandoTodas,
                        onPressed:
                            n == 0 || _busy
                                ? null
                                : () =>
                                    _aplicarSelecionadas(args, selecionadas),
                      ),
                    ),
                  ),
              ],
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
              _successBanner != null
                  ? 'Tudo em dia'
                  : 'Nenhuma sugestão pendente',
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
            child: FxTonalButton(
              label: 'Voltar ao Aluno 360',
              icon: Icons.arrow_back_rounded,
              onPressed:
                  () => safePopOrGo(
                    context,
                    args.returnTo ?? '/alunos/${args.alunoId}',
                  ),
              compact: true,
            ),
          ),
      ],
    );
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
          friendlyError(
            e,
            fallback: 'Não foi possível descartar as sugestões.',
          ),
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

/// O que a revisão tem pela frente, em uma olhada.
class _ResumoDaRevisao extends StatelessWidget {
  const _ResumoDaRevisao({required this.sugestoes});

  final List<ProgressaoSugestao> sugestoes;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final sobe = sugestoes.where((s) => (s.deltaKg ?? 0) > 0).length;
    final desce = sugestoes.where((s) => (s.deltaKg ?? 0) < 0).length;
    final mantem = sugestoes.length - sobe - desce;
    return FxStripCard(
      marca: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ptS.cargasParaRevisar(sugestoes.length),
              style: FocuxHubTypography.cardTitle(color: sobre.ink),
            ),
            Text(
              [
                if (sobe > 0) ptS.cargasResumoSobe(sobe),
                if (desce > 0) ptS.cargasResumoDesce(desce),
                if (mantem > 0) ptS.cargasResumoMantem(mantem),
              ].join(' · '),
              style: FocuxHubTypography.bodyMuted(color: sobre.mute),
            ),
          ],
        ),
      ),
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
              const Icon(
                Icons.search_off_rounded,
                size: 18,
                color: EagleTokens.warn,
              ),
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
                child: FxTonalButton(
                  label: progressaoDescartarTodas,
                  danger: true,
                  expanded: true,
                  onPressed: busy ? null : onDiscard,
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: FxTonalButton(
                  label: progressaoTentarDeNovo,
                  expanded: true,
                  onPressed: busy ? null : onRetry,
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

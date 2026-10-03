import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../moderacao/data/moderacao_repository.dart';
import '../../moderacao/widgets/denunciar_sheet.dart';
import '../data/ia_repository.dart';
import '../models/ia_progressao_carga_result.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../utils/progressao_copy.dart';
import '../utils/progressao_pdf_builder.dart';
import '../../../core/pdf/focux_pdf_kit.dart';
import '../widgets/ia_progressao_loading_skeleton.dart';
import '../widgets/ia_progressao_pedido_card.dart';
import '../widgets/ia_progressao_result_view.dart';
import '../widgets/ia_quota_upgrade.dart';

class IaProgressaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const IaProgressaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<IaProgressaoScreen> createState() => _IaProgressaoScreenState();
}

class _IaProgressaoScreenState extends ConsumerState<IaProgressaoScreen> {
  final _observacoes = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();
  final _openedAt = DateTime.now();
  var _objetivo = ProgressaoObjetivo.hipertrofia;
  bool _loading = false;
  bool _exportando = false;
  IaProgressaoCargaResult? _resultado;
  String? _erro;
  var _viewTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackViewIfNeeded());
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoViewed,
      props: {'alunoId': widget.alunoId},
    );
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoTtv,
      props: {
        'alunoId': widget.alunoId,
        'ms': DateTime.now().difference(_openedAt).inMilliseconds,
      },
    );
  }

  Future<void> _exportarPdf(IaProgressaoCargaResult resultado) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final agora = resultado.geradoEm ?? DateTime.now();
      final bytes = await buildProgressaoPdf(
        result: resultado,
        alunoNome: widget.alunoNome,
        personalNome: ref.read(personalNameProvider),
        assets: await FocuxPdfAssets.load(),
        agora: agora,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: progressaoPdfFileName(widget.alunoNome, agora),
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

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _resultKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: fxMotionDuration(context),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _showHelp() {
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoHelpOpened,
      props: {'alunoId': widget.alunoId},
    );
    showFxHelpSheet(
      context,
      title: 'Progressão de carga',
      subtitle: progressaoHubSubtitle(widget.alunoNome),
      tips: const [
        FxHelpTip(
          'Dados reais',
          'A IA lê o treino ativo e as execuções das últimas 4 semanas. Você só escolhe o objetivo.',
          icon: 'target',
        ),
        FxHelpTip(
          'Opt-in',
          'Nada é gerado sozinho. A cota só é usada quando a sugestão chega.',
          icon: 'spark',
        ),
        FxHelpTip(
          'Reversível',
          'Sugestões ficam pendentes. Carga, séries e repetições só mudam se você aceitar.',
          icon: 'circle-check',
        ),
      ],
    );
  }

  void _abrirAceitar() {
    context.push(
      '/ia/progressao/aceitar',
      extra: ProgressaoAceitarRouteArgs(
        returnTo: '/alunos/${widget.alunoId}',
        alunoId: widget.alunoId,
        alunoNome: widget.alunoNome,
      ).toExtra(),
    );
  }

  void _abrirTreinos() {
    context.push(
      '/alunos/${widget.alunoId}/treinos-list',
      extra: widget.alunoNome,
    );
  }

  Future<void> _gerar() async {
    if (_loading) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: progressaoConfirmTitle(),
      message: progressaoConfirmMessage(),
      icon: Icons.auto_awesome_outlined,
      confirmLabel: progressaoConfirmLabel(),
    );
    if (!ok || !mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoCtaTapped,
      props: {'alunoId': widget.alunoId, 'objetivo': _objetivo.api},
    );
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(
        widget.alunoId,
        objetivo: _objetivo.api,
        observacoes: _observacoes.text.trim(),
      );
      if (!mounted) return;
      setState(() => _resultado = r);
      _scrollToResult();
      ref.invalidate(progressaoSugestoesProvider(widget.alunoId));
      if (r.sugestoesRegistradas > 0) {
        FeedbackHelper.showSuccess(
          context,
          progressaoSavedForReviewSnack(r.sugestoesRegistradas),
        );
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is IaOperationalException
                ? e.message
                : friendlyError(
                  e,
                  fallback:
                      'Não consegui falar com a IA agora. Tente novamente em alguns segundos.',
                );
        setState(() => _erro = message);
        if (_resultado != null) {
          FeedbackHelper.showInfo(context, progressaoErroManteveResultado);
        }
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _observacoes.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final abertas =
        ref.watch(progressaoSugestoesProvider(widget.alunoId)).value ??
        const [];
    final pending = abertas.where((s) => !s.naoEncontrada).toList();
    final contexto = ref.watch(progressaoContextoProvider(widget.alunoId));
    final semTreino = isSemTreinoAtivo(contexto.error);
    final resultado = _resultado;

    return fxScreenA11yScope(
      label: 'Progressão de Carga',
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Progressão de carga',
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona a progressão',
                onTap: _showHelp,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                    ),
                    child: Aluno360Layout.operacaoContentWidthLimiter(
                      child: FxContentWidthLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FxHubHeader(
                              title: widget.alunoNome,
                              subtitle: progressaoHubSubtitle(widget.alunoNome),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: TokensStrip.s4,
                                bottom: TokensStrip.s3,
                              ),
                              child: OperationalMetricTile(
                                label: 'Pendentes',
                                value: '${pending.length}',
                                hint: progressaoPendingMetricHint(
                                  pending.length,
                                ),
                                color: primary,
                                isDark: isDark,
                              ),
                            ),
                            Wrap(
                              spacing: TokensStrip.s2,
                              runSpacing: TokensStrip.s2,
                              children: [
                                if (abertas.isNotEmpty)
                                  FxActionChip(
                                    label: progressaoPendingReviewLabel(
                                      abertas.length,
                                    ),
                                    accent: primary,
                                    isDark: isDark,
                                    onPressed: _abrirAceitar,
                                  ),
                                FxActionChip(
                                  label: 'Treinos',
                                  accent: primary,
                                  isDark: isDark,
                                  onPressed: _abrirTreinos,
                                ),
                                FxActionChip(
                                  label: 'Evolução',
                                  accent: primary,
                                  isDark: isDark,
                                  onPressed:
                                      () => context.push(
                                        '/alunos/${widget.alunoId}/evolucao',
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            const DashboardSectionHeader(title: 'Pedido'),
                            const SizedBox(height: TokensStrip.s2),
                            IaProgressaoPedidoCard(
                              contexto: contexto,
                              objetivo: _objetivo,
                              onObjetivo:
                                  (o) => setState(() => _objetivo = o),
                              observacoes: _observacoes,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            const IaSafetyDisclaimer(compact: true),
                            if (_erro != null) ...[
                              const SizedBox(height: TokensStrip.s4),
                              FxErrorState(
                                chromeOnDark: chrome.isDark,
                                primary: primary,
                                message: _erro!,
                                onRetry: _gerar,
                              ),
                            ],
                            if (_loading) const IaProgressaoLoadingSkeleton(),
                            if (resultado != null && !_loading)
                              KeyedSubtree(
                                key: _resultKey,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: TokensStrip.s5,
                                  ),
                                  child: IaProgressaoResultView(
                                    result: resultado,
                                    alunoNome: widget.alunoNome,
                                    onExportPdf:
                                        _exportando
                                            ? null
                                            : () => _exportarPdf(resultado),
                                    onReviewSuggestions: _abrirAceitar,
                                    onReport: () => showDenunciarSheet(
                                      context,
                                      repo: ModeracaoRepository(
                                        ref.read(apiClientProvider),
                                      ),
                                      tipo: DenunciaTipo.iaResposta,
                                      conteudo: resultado.resposta,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                  child: Semantics(
                    button: true,
                    enabled: !_loading,
                    label:
                        _loading
                            ? 'Gerando progressão com IA'
                            : semTreino
                            ? progressaoAbrirTreino
                            : progressaoStickyLabel(
                              hasResult: resultado != null,
                            ),
                    child: FxLiquidPrimaryButton(
                      label:
                          semTreino
                              ? progressaoAbrirTreino
                              : progressaoStickyLabel(
                                hasResult: resultado != null,
                              ),
                      loading: _loading,
                      loadingLabel: progressaoStickyLoadingLabel(),
                      onPressed:
                          _loading
                              ? null
                              : semTreino
                              ? _abrirTreinos
                              : _gerar,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

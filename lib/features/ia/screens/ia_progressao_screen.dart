import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/ia_repository.dart';
import '../models/ia_progressao_carga_result.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/ia_progressao_input_normalizer.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../utils/progressao_copy.dart';
import '../widgets/ia_progressao_loading_skeleton.dart';
import '../widgets/ia_progressao_result_view.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';

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
  final _objetivo = TextEditingController();
  final _historico = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();
  bool _loading = false;
  IaProgressaoCargaResult? _resultado;
  String? _erro;

  Future<void> _exportarPdf(IaProgressaoCargaResult resultado) async {
    final parsed = resultado.toParsed();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final blocks = <pw.Widget>[
            pw.Text(
              'Progressão de Carga — ${widget.alunoNome}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
          ];

          if (parsed.hasStructuredRows) {
            if (parsed.intro != null && parsed.intro!.isNotEmpty) {
              blocks.add(
                pw.Text(parsed.intro!, style: const pw.TextStyle(fontSize: 11)),
              );
              blocks.add(pw.SizedBox(height: 12));
            }
            for (final row in parsed.exercises) {
              blocks.addAll([
                pw.Text(
                  row.exercicio,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Atual: ${row.cargaAtual}  →  Sugerido: ${row.cargaSugerida}'
                  '${row.deltaLabel != null ? ' (${row.deltaLabel})' : ''}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                if (row.justificativa.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    row.justificativa,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
                pw.SizedBox(height: 12),
              ]);
            }
            if (parsed.footer != null && parsed.footer!.isNotEmpty) {
              blocks.add(
                pw.Text(
                  parsed.footer!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              );
            }
          } else {
            blocks.addAll(
              resultado.resposta
                  .split('\n')
                  .map(
                    (l) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        l
                            .replaceAll(RegExp(r'^#+\s*'), '')
                            .replaceAll('**', ''),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
            );
          }
          return blocks;
        },
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'progressao_carga.pdf',
    );
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, 'PDF pronto para compartilhar.');
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
    showFxHelpSheet(
      context,
      title: 'Progressão de carga',
      subtitle: progressaoHubSubtitle(widget.alunoNome),
      tips: const [
        FxHelpTip(
          'Pedido',
          'Objetivo e histórico são opcionais. A IA usa o que você escrever.',
          icon: 'target',
        ),
        FxHelpTip(
          'Opt-in',
          'Nada é gerado sozinho. Confirme antes de gastar a cota.',
          icon: 'spark',
        ),
        FxHelpTip(
          'Reversível',
          'Sugestões ficam pendentes. Só entram no treino se você aceitar.',
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
    setState(() {
      _loading = true;
      _resultado = null;
      _erro = null;
    });
    try {
      final historico = normalizeIaProgressaoHistorico(_historico.text);
      final objetivo = normalizeIaProgressaoObjetivo(_objetivo.text);
      if (iaProgressaoHistoricoWasNormalized(_historico.text, historico) &&
          mounted) {
        FeedbackHelper.showInfo(
          context,
          'Histórico ajustado (séries e nomes de exercício padronizados).',
        );
      }
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(
        widget.alunoId,
        objetivo: objetivo.isEmpty ? null : objetivo,
        historicoTreinos: historico.isEmpty ? null : historico,
      );
      if (!mounted) return;
      setState(() => _resultado = r);
      _scrollToResult();
      if (r.sugestoesRegistradas > 0) {
        ref.invalidate(progressaoSugestoesProvider(widget.alunoId));
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
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _objetivo.dispose();
    _historico.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending =
        ref.watch(progressaoSugestoesProvider(widget.alunoId)).valueOrNull ??
        const [];
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
                tooltip: 'Como pedir progressão',
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
                                if (pending.isNotEmpty)
                                  DashboardHomeActionChip(
                                    label: progressaoPendingReviewLabel(
                                      pending.length,
                                    ),
                                    accent: primary,
                                    isDark: isDark,
                                    onPressed: () => _abrirAceitar(),
                                  ),
                                DashboardHomeActionChip(
                                  label: 'Treinos',
                                  accent: primary,
                                  isDark: isDark,
                                  onPressed:
                                      () => context.push(
                                        '/alunos/${widget.alunoId}/treinos-list',
                                        extra: widget.alunoNome,
                                      ),
                                ),
                                DashboardHomeActionChip(
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
                            AlunoInsetFormField(
                              controller: _objetivo,
                              label: 'Objetivo',
                              hint: 'Hipertrofia, força, emagrecimento',
                              icon: Icons.flag_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  progressaoObjetivoMax,
                                ),
                              ],
                            ),
                            AlunoInsetFormField(
                              controller: _historico,
                              label: 'Histórico recente',
                              hint: 'Supino 80kg 3x8, Agachamento 100kg 4x6',
                              icon: Icons.notes_outlined,
                              maxLines: 5,
                              showDivider: false,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  progressaoHistoricoMax,
                                ),
                              ],
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            const IaSafetyDisclaimer(compact: true),
                            if (_loading) const IaProgressaoLoadingSkeleton(),
                            if (_erro != null) ...[
                              const SizedBox(height: TokensStrip.s4),
                              FxErrorState(
                                chromeOnDark: chrome.isDark,
                                primary: primary,
                                message: _erro!,
                                onRetry: _gerar,
                              ),
                            ],
                            if (_resultado != null) ...[
                              KeyedSubtree(
                                key: _resultKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: TokensStrip.s5),
                                    IaProgressaoResultView(
                                      result: _resultado!,
                                      alunoNome: widget.alunoNome,
                                      onExportPdf:
                                          () => _exportarPdf(_resultado!),
                                      onApplyTreino: () {
                                        FeedbackHelper.showInfo(
                                          context,
                                          'Abra o treino ativo para conferir ou ajustar as cargas.',
                                        );
                                        context.push(
                                          '/alunos/${widget.alunoId}/treinos-list',
                                          extra: widget.alunoNome,
                                        );
                                      },
                                      onReviewSuggestions: _abrirAceitar,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                            : progressaoStickyLabel(
                              hasResult: _resultado != null,
                            ),
                    child: FxLiquidPrimaryButton(
                      label: progressaoStickyLabel(
                        hasResult: _resultado != null,
                      ),
                      loading: _loading,
                      loadingLabel: progressaoStickyLoadingLabel(),
                      onPressed: _loading ? null : _gerar,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
import '../models/ia_progressao_carga_result.dart';
import '../widgets/ia_progressao_loading_skeleton.dart';
import '../widgets/ia_progressao_result_view.dart';
import '../utils/ia_progressao_input_normalizer.dart';
import '../utils/progressao_copy.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../widgets/ia_quota_upgrade.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

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
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
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
              blocks.add(pw.Text(parsed.intro!, style: const pw.TextStyle(fontSize: 11)));
              blocks.add(pw.SizedBox(height: 12));
            }
            for (final row in parsed.exercises) {
              blocks.addAll([
                pw.Text(
                  row.exercicio,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
              blocks.add(pw.Text(parsed.footer!, style: const pw.TextStyle(fontSize: 10)));
            }
          } else {
            blocks.addAll(
              resultado.resposta.split('\n').map(
                (l) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', ''),
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

  Future<void> _gerar() async {
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
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
        FeedbackHelper.showSuccess(context, progressaoSavedForReviewSnack(r.sugestoesRegistradas));
      }
    } catch (e) {
      if (mounted) {
        final message = e is IaOperationalException
            ? e.message
            : 'Não consegui falar com a IA agora. Tente novamente em alguns segundos.';
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
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Progressão de Carga',
        subtitle: widget.alunoNome,
        onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Aluno360Layout.operacaoContentWidthLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: fxListCardDecoration(context, accent: primary),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parâmetros',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _objetivo,
                        decoration: InputDecoration(
                          labelText: 'Objetivo (ex: hipertrofia, força)',
                          hintText: 'Ex: hipertrofia, força máxima, emagrecimento',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(TokensStrip.rCard),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _historico,
                        decoration: InputDecoration(
                          labelText:
                              'Histórico de treinos (cargas e repetições recentes)',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(TokensStrip.rCard),
                          ),
                          hintText:
                              'Ex: Supino 80kg 3x8, Agachamento 100kg 4x6...',
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const IaSafetyDisclaimer(compact: true),
              const SizedBox(height: 12),
              FxLiquidPrimaryButton(
                label: _loading ? 'Analisando...' : 'Gerar Progressão com IA',
                icon: Icons.trending_up,
                loading: _loading,
                onPressed: _loading ? null : _gerar,
              ),
              if (_loading) const IaProgressaoLoadingSkeleton(),
              if (_erro != null) ...[
                const SizedBox(height: TokensStrip.s4),
                Container(
                  decoration: fxListCardDecoration(context, accent: primary),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'IA indisponível',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_erro!),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _gerar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_resultado != null) ...[
                KeyedSubtree(
                  key: _resultKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                      IaProgressaoResultView(
                        result: _resultado!,
                        alunoNome: widget.alunoNome,
                        onExportPdf: () => _exportarPdf(_resultado!),
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
                        onReviewSuggestions:
                            () => context.push(
                              '/ia/progressao/aceitar',
                              extra: ProgressaoAceitarRouteArgs(
                                returnTo: '/alunos/${widget.alunoId}',
                                alunoId: widget.alunoId,
                                alunoNome: widget.alunoNome,
                              ).toExtra(),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

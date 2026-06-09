import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
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
  bool _loading = false;
  String? _resultado;
  String? _erro;

  Future<void> _exportarPdf(String conteudo) async {
    final doc = pw.Document();
    final linhas = conteudo.split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (ctx) => [
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
              ...linhas.map(
                (l) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', ''),
                    style: pw.TextStyle(
                      fontSize: l.startsWith('#') ? 13 : 11,
                      fontWeight:
                          l.startsWith('#')
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'progressao_carga.pdf',
    );
  }

  Future<void> _gerar() async {
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    setState(() {
      _loading = true;
      _resultado = null;
      _erro = null;
    });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(
        widget.alunoId,
        objetivo: _objetivo.text,
        historicoTreinos: _historico.text,
      );
      setState(() => _resultado = r);
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
        padding: const EdgeInsets.all(TokensStrip.s4),
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
                      hintText: 'Ex: Supino 80kg 3x8, Agachamento 100kg 4x6...',
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
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            MarkdownBody(data: _resultado!, selectable: true),
            const SizedBox(height: TokensStrip.s4),
            OutlinedButton.icon(
              onPressed: () => _exportarPdf(_resultado!),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF'),
            ),
          ],
        ],
      ),
    ),
  );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

class IaProgressaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const IaProgressaoScreen({super.key, required this.alunoId, required this.alunoNome});

  @override
  ConsumerState<IaProgressaoScreen> createState() => _IaProgressaoScreenState();
}

class _IaProgressaoScreenState extends ConsumerState<IaProgressaoScreen> {
  final _objetivo = TextEditingController();
  final _historico = TextEditingController();
  bool _loading = false;
  String? _resultado;

  Future<void> _exportarPdf(String conteudo) async {
    final doc = pw.Document();
    final linhas = conteudo.split('\n');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('Progressão de Carga — ${widget.alunoNome}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Gerado em: ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 20),
        ...linhas.map((l) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', ''),
            style: pw.TextStyle(
              fontSize: l.startsWith('#') ? 13 : 11,
              fontWeight: l.startsWith('#') ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        )),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'progressao_carga.pdf');
  }

  Future<void> _gerar() async {
    setState(() { _loading = true; _resultado = null; });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(widget.alunoId,
          objetivo: _objetivo.text, historicoTreinos: _historico.text);
      setState(() => _resultado = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Progressão de Carga — ${widget.alunoNome}')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parâmetros', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _objetivo,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo (ex: hipertrofia, força)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _historico,
                  decoration: const InputDecoration(
                    labelText: 'Histórico de treinos (cargas e repetições recentes)',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Supino 80kg 3x8, Agachamento 100kg 4x6...',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _gerar,
          icon: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.trending_up),
          label: Text(_loading ? 'Analisando...' : 'Gerar Progressão com IA'),
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          MarkdownBody(data: _resultado!, selectable: true),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _exportarPdf(_resultado!),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
          ),
        ],
      ]),
    ),
  );
}

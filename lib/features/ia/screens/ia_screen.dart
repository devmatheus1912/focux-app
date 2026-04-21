import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

class IaScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const IaScreen({super.key, required this.alunoId});
  @override
  ConsumerState<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends ConsumerState<IaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('IA Focux'),
      bottom: TabBar(controller: _tabs, tabs: const [
        Tab(icon: Icon(Icons.fitness_center), text: 'Treino'),
        Tab(icon: Icon(Icons.restaurant_menu), text: 'Dieta'),
      ]),
    ),
    body: TabBarView(controller: _tabs, children: [
      _GerarTreinoTab(alunoId: widget.alunoId),
      _GerarDietaTab(alunoId: widget.alunoId),
    ]),
  );
}

class _GerarTreinoTab extends ConsumerStatefulWidget {
  final int alunoId;
  const _GerarTreinoTab({required this.alunoId});
  @override
  ConsumerState<_GerarTreinoTab> createState() => _GerarTreinoTabState();
}

class _GerarTreinoTabState extends ConsumerState<_GerarTreinoTab> {
  final _objetivo = TextEditingController();
  final _restricoes = TextEditingController();
  final _equipamentos = TextEditingController();
  String _nivel = 'Intermediário';
  int _dias = 3;
  bool _loading = false;
  String? _resultado;

  Future<void> _exportarPdf(String conteudo, String titulo) async {
    final doc = pw.Document();
    final linhas = conteudo.split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(titulo,
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text(
            'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),
          ...linhas.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', ''),
              style: pw.TextStyle(
                fontSize: l.startsWith('#') ? 14 : 11,
                fontWeight: l.startsWith('#')
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
    await Printing.sharePdf(
        bytes: await doc.save(), filename: '$titulo.pdf');
  }

  Future<void> _gerar() async {
    setState(() { _loading = true; _resultado = null; });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.gerarTreino(widget.alunoId,
        objetivo: _objetivo.text, nivelAtividade: _nivel,
        restricoes: _restricoes.text, diasPorSemana: _dias,
        equipamentos: _equipamentos.text);
      setState(() => _resultado = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _field(_objetivo, 'Objetivo (ex: hipertrofia, emagrecimento)'),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _nivel,
        decoration: const InputDecoration(labelText: 'Nível de atividade'),
        items: ['Sedentário', 'Iniciante', 'Intermediário', 'Avançado']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _nivel = v!),
      ),
      const SizedBox(height: 12),
      Row(children: [
        const Text('Dias por semana: '),
        Expanded(child: Slider(value: _dias.toDouble(), min: 2, max: 6, divisions: 4,
          label: '$_dias dias', onChanged: (v) => setState(() => _dias = v.round()))),
        Text('$_dias'),
      ]),
      _field(_restricoes, 'Restrições / lesões'),
      const SizedBox(height: 4),
      _field(_equipamentos, 'Equipamentos disponíveis'),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _gerar,
        icon: _loading ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Gerando...' : 'Gerar Treino com IA'),
      ),
      if (_resultado != null) ...[
        const SizedBox(height: 20),
        const Divider(),
        MarkdownBody(data: _resultado!, selectable: true),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _exportarPdf(_resultado!, 'Plano de Treino'),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exportar PDF'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            try {
              final repo = IaRepository(ref.read(apiClientProvider));
              final sucesso = await repo.confirmarPublicar(widget.alunoId);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano de treino publicado no app do aluno com sucesso!')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
            }
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Publicar no App do Aluno'),
        ),
      ],
    ]),
  );

  Widget _field(TextEditingController c, String label) =>
      TextFormField(controller: c, decoration: InputDecoration(labelText: label));
}

class _GerarDietaTab extends ConsumerStatefulWidget {
  final int alunoId;
  const _GerarDietaTab({required this.alunoId});
  @override
  ConsumerState<_GerarDietaTab> createState() => _GerarDietaTabState();
}

class _GerarDietaTabState extends ConsumerState<_GerarDietaTab> {
  final _objetivo = TextEditingController();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _restricoes = TextEditingController();
  final _calorias = TextEditingController();
  bool _loading = false;
  String? _resultado;

  Future<void> _exportarPdf(String conteudo, String titulo) async {
    final doc = pw.Document();
    final linhas = conteudo.split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(titulo,
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text(
            'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),
          ...linhas.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', ''),
              style: pw.TextStyle(
                fontSize: l.startsWith('#') ? 14 : 11,
                fontWeight: l.startsWith('#')
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
    await Printing.sharePdf(
        bytes: await doc.save(), filename: '$titulo.pdf');
  }

  Future<void> _gerar() async {
    setState(() { _loading = true; _resultado = null; });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.gerarDieta(widget.alunoId,
        objetivo: _objetivo.text,
        pesoKg: int.tryParse(_peso.text),
        alturaCm: int.tryParse(_altura.text),
        restricoes: _restricoes.text,
        caloriasAlvo: int.tryParse(_calorias.text));
      setState(() => _resultado = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _field(_objetivo, 'Objetivo (ex: hipertrofia, emagrecimento, saúde)'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _num(_peso, 'Peso (kg)')),
        const SizedBox(width: 12),
        Expanded(child: _num(_altura, 'Altura (cm)')),
      ]),
      const SizedBox(height: 8),
      _num(_calorias, 'Meta calórica diária (opcional)'),
      const SizedBox(height: 8),
      _field(_restricoes, 'Restrições alimentares / alergias'),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _gerar,
        icon: _loading ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Gerando...' : 'Gerar Dieta com IA'),
      ),
      if (_resultado != null) ...[
        const SizedBox(height: 20),
        const Divider(),
        MarkdownBody(data: _resultado!, selectable: true),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _exportarPdf(_resultado!, 'Plano Alimentar'),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exportar PDF'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            try {
              final repo = IaRepository(ref.read(apiClientProvider));
              final sucesso = await repo.confirmarPublicar(widget.alunoId);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano alimentar publicado no app do aluno com sucesso!')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
            }
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Publicar no App do Aluno'),
        ),
      ],
    ]),
  );

  Widget _field(TextEditingController c, String label) =>
      TextFormField(controller: c, decoration: InputDecoration(labelText: label));
  Widget _num(TextEditingController c, String label) =>
      TextFormField(controller: c, decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number);
}

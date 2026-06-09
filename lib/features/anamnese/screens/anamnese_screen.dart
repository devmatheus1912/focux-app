import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/anamnese_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class AnamneseScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AnamneseScreen({super.key, required this.alunoId});
  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 — Básico
  final _objetivoCtrl = TextEditingController();
  String? _nivelAtividade;
  final _lesoesCtrl = TextEditingController();
  final _medicCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  // Tab 2 — Saúde
  final _historicoCtrl = TextEditingController();
  final _cirurgiasCtrl = TextEditingController();
  final _doresCtrl = TextEditingController();

  // Tab 3 — Treino & Nutrição
  final _objDetalhadoCtrl = TextEditingController();
  int _dispSemanal = 3;
  final _prefTreinoCtrl = TextEditingController();
  final _restricoesCtrl = TextEditingController();

  bool _loading = true, _saving = false;

  static const _niveis = [
    'SEDENTARIO',
    'LEVE',
    'MODERADO',
    'INTENSO',
    'MUITO_INTENSO',
  ];
  static const _niveisLabel = {
    'SEDENTARIO': 'Sedentário',
    'LEVE': 'Leve',
    'MODERADO': 'Moderado',
    'INTENSO': 'Intenso',
    'MUITO_INTENSO': 'Muito Intenso',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _objetivoCtrl.dispose();
    _lesoesCtrl.dispose();
    _medicCtrl.dispose();
    _obsCtrl.dispose();
    _historicoCtrl.dispose();
    _cirurgiasCtrl.dispose();
    _doresCtrl.dispose();
    _objDetalhadoCtrl.dispose();
    _prefTreinoCtrl.dispose();
    _restricoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final a = await AnamneseRepository(
        ref.read(apiClientProvider),
      ).buscar(widget.alunoId);
      _objetivoCtrl.text = a.objetivo ?? '';
      _nivelAtividade =
          _niveis.contains(a.nivelAtividade) ? a.nivelAtividade : null;
      _lesoesCtrl.text = a.lesoes ?? '';
      _medicCtrl.text = a.medicamentos ?? '';
      _obsCtrl.text = a.observacoes ?? '';
      _historicoCtrl.text = a.historicoMedico ?? '';
      _cirurgiasCtrl.text = a.cirurgias ?? '';
      _doresCtrl.text = a.doresCronicas ?? '';
      _objDetalhadoCtrl.text = a.objetivoDetalhado ?? '';
      _dispSemanal = a.disponibilidadeSemanal ?? 3;
      _prefTreinoCtrl.text = a.preferenciasTreino ?? '';
      _restricoesCtrl.text = a.restricoesAlimentares ?? '';
    } catch (e) {
      debugPrint('[Focux] Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportarPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (ctx) => [
              pw.Text(
                'Ficha de Anamnese',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              _pdfSecao('Básico'),
              _pdfCampo('Objetivo', _objetivoCtrl.text),
              _pdfCampo('Nível de atividade', _nivelAtividade ?? '—'),
              _pdfCampo('Lesões / Limitações', _lesoesCtrl.text),
              _pdfCampo('Medicamentos', _medicCtrl.text),
              _pdfCampo('Observações', _obsCtrl.text),
              pw.SizedBox(height: 12),
              _pdfSecao('Saúde'),
              _pdfCampo('Histórico médico', _historicoCtrl.text),
              _pdfCampo('Cirurgias', _cirurgiasCtrl.text),
              _pdfCampo('Dores crônicas', _doresCtrl.text),
              pw.SizedBox(height: 12),
              _pdfSecao('Treino & Nutrição'),
              _pdfCampo('Objetivo detalhado', _objDetalhadoCtrl.text),
              _pdfCampo('Disponibilidade semanal', '$_dispSemanal dias/semana'),
              _pdfCampo('Preferências de treino', _prefTreinoCtrl.text),
              _pdfCampo('Restrições alimentares', _restricoesCtrl.text),
            ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfSecao(String titulo) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      titulo,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey700,
      ),
    ),
  );

  pw.Widget _pdfCampo(String label, String value) {
    if (value.trim().isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await AnamneseRepository(
        ref.read(apiClientProvider),
      ).salvar(widget.alunoId, {
        'objetivo': _objetivoCtrl.text,
        if (_nivelAtividade != null) 'nivelAtividade': _nivelAtividade,
        'lesoes': _lesoesCtrl.text,
        'medicamentos': _medicCtrl.text,
        'observacoes': _obsCtrl.text,
        'historicoMedico': _historicoCtrl.text,
        'cirurgias': _cirurgiasCtrl.text,
        'doresCronicas': _doresCtrl.text,
        'objetivoDetalhado': _objDetalhadoCtrl.text,
        'disponibilidadeSemanal': _dispSemanal,
        'preferenciasTreino': _prefTreinoCtrl.text,
        'restricoesAlimentares': _restricoesCtrl.text,
      });
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Anamnese salva!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Erro: $e');
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: FxLoading());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      useMesh: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Anamnese',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
        ),
        bottom: TabBar(
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor:
              isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
          indicatorWeight: 2.5,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Básico'),
            Tab(text: 'Saúde'),
            Tab(text: 'Treino & Nutrição'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _exportarPdf,
          ),
          TextButton(
            onPressed: _saving ? null : _salvar,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: FxLoading(strokeWidth: 2),
                    )
                    : const Text('Salvar'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_tabBasico(), _tabSaude(), _tabTreinoNutricao()],
      ),
    );
  }

  Widget _tabBasico() => SingleChildScrollView(
    padding: const EdgeInsets.all(TokensStrip.s4),
    child: Column(
      children: [
        _field(
          _objetivoCtrl,
          'Objetivo',
          maxLines: 2,
          hint: 'Ex.: hipertrofia, emagrecimento, condicionamento',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _nivelAtividade,
          decoration: const InputDecoration(
            labelText: 'Nível de atividade física',
          ),
          items:
              _niveis
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(_niveisLabel[n] ?? n),
                    ),
                  )
                  .toList(),
          onChanged: (v) => setState(() => _nivelAtividade = v),
        ),
        const SizedBox(height: 12),
        _field(
          _lesoesCtrl,
          'Lesões / Limitações',
          maxLines: 3,
          hint: 'Ex.: joelho, lombar, evitar impacto',
        ),
        _field(
          _medicCtrl,
          'Medicamentos em uso',
          maxLines: 2,
          hint: 'Ex.: anti-hipertensivo, tireoide',
        ),
        _field(
          _obsCtrl,
          'Observações gerais',
          maxLines: 3,
          hint: 'Rotina, sono, estresse, preferências',
        ),
        const SizedBox(height: 80),
      ],
    ),
  );

  Widget _tabSaude() => SingleChildScrollView(
    padding: const EdgeInsets.all(TokensStrip.s4),
    child: Column(
      children: [
        _field(
          _historicoCtrl,
          'Histórico médico',
          maxLines: 4,
          hint: 'Doenças, diagnósticos, acompanhamentos',
        ),
        _field(
          _cirurgiasCtrl,
          'Cirurgias realizadas',
          maxLines: 3,
          hint: 'Ex.: LCA, hérnia, quando ocorreu',
        ),
        _field(
          _doresCtrl,
          'Dores crônicas',
          maxLines: 3,
          hint: 'Ex.: cervical, ombro direito',
        ),
        const SizedBox(height: 80),
      ],
    ),
  );

  Widget _tabTreinoNutricao() => SingleChildScrollView(
    padding: const EdgeInsets.all(TokensStrip.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          _objDetalhadoCtrl,
          'Objetivo detalhado',
          maxLines: 3,
          hint: 'Meta em 8–12 semanas, eventos, prioridades',
        ),
        const SizedBox(height: TokensStrip.s4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Disponibilidade semanal: $_dispSemanal dias/semana',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: TokensStrip.borderDefault,
            thumbColor: Theme.of(context).colorScheme.surface,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _dispSemanal.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_dispSemanal dias',
            onChanged: (v) => setState(() => _dispSemanal = v.round()),
          ),
        ),
        const SizedBox(height: 8),
        _field(
          _prefTreinoCtrl,
          'Preferências de treino',
          maxLines: 3,
          hint: 'Ex.: manhã, musculação, evitar corrida',
        ),
        _field(
          _restricoesCtrl,
          'Restrições alimentares',
          maxLines: 3,
          hint: 'Ex.: lactose, vegetariano, alergias',
        ),
        const SizedBox(height: 80),
      ],
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: TokensStrip.textSecondary.withValues(alpha: 0.72),
            ),
          ),
          maxLines: maxLines,
        ),
      );
}

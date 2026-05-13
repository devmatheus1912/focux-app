import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';
import '../../../core/widgets/fx_loading.dart';

class RelatorioScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const RelatorioScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends ConsumerState<RelatorioScreen> {
  int _dias = 30;
  DateTimeRange? _rangeCustom;
  AderenciaData? _dados;
  ComparativoPeriodo? _comparativo;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _escolherPeriodoCustom() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange:
          _rangeCustom ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() => _rangeCustom = range);
      _carregarDados();
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final repo = RelatorioRepository(ref.read(apiClientProvider));
      final results = await Future.wait([
        repo.aderencia(
          widget.alunoId,
          dias: _dias,
          inicio: _rangeCustom?.start,
          fim: _rangeCustom?.end,
        ),
        repo
            .comparativo(widget.alunoId, dias: _dias)
            .then<ComparativoPeriodo?>((v) => v)
            .catchError((_) => null as ComparativoPeriodo?),
      ]);
      if (mounted) {
        setState(() {
          _dados = results[0] as AderenciaData;
          _comparativo = results[1] as ComparativoPeriodo?;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    if (_dados == null) return;
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final d = _dados!;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório de Aderência — ${widget.alunoNome}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Período Analisado: $_dias dias',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfCard(
                    'Taxa de Aderência',
                    '${d.taxaAderenciaPercent.toStringAsFixed(1)}%',
                  ),
                  _pdfCard(
                    'Treinos Concluídos',
                    '${d.treinosConcluidos} / ${d.treinosTotal}',
                  ),
                  _pdfCard('Dias Analisados', '${d.diasAnalisados}'),
                ],
              ),
              pw.SizedBox(height: 24),
              if (_comparativo != null) ...[
                pw.Text(
                  'Comparativo com Período Anterior',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Aderência Atual: ${_comparativo!.aderenciaAtual.toStringAsFixed(1)}% (${_comparativo!.checkInsAtual} check-ins)',
                ),
                pw.Text(
                  'Aderência Anterior: ${_comparativo!.aderenciaAnterior.toStringAsFixed(1)}% (${_comparativo!.checkInsAnterior} check-ins)',
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Evolução: ${(_comparativo!.aderenciaAtual - _comparativo!.aderenciaAnterior).toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color:
                        _comparativo!.aderenciaAtual >=
                                _comparativo!.aderenciaAnterior
                            ? PdfColors.green
                            : PdfColors.red,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        title: Text(
          'Relatório — ${widget.alunoNome}',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            tooltip: 'Exportar PDF',
            onPressed: _dados != null ? _exportarPdf : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SeletorPeriodo(
              diasSelecionado: _dias,
              rangeCustom: _rangeCustom,
              onChanged: (dias) {
                setState(() {
                  _dias = dias;
                  _rangeCustom = null;
                });
                _carregarDados();
              },
              onCustom: _escolherPeriodoCustom,
            ),
            const SizedBox(height: 20),
            if (_carregando)
              const SizedBox(height: 200, child: FxLoading())
            else if (_erro != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erro ao carregar relatório: $_erro',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              )
            else if (_dados != null) ...[
              _CardAderencia(dados: _dados!),
              const SizedBox(height: 16),
              if (_comparativo != null) ...[
                _CardComparativo(comparativo: _comparativo!),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: _CardInfo(
                      icone: Icons.check_circle_outline,
                      titulo: 'Treinos Concluídos',
                      valor:
                          '${_dados!.treinosConcluidos} / ${_dados!.treinosTotal}',
                      cor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardInfo(
                      icone: Icons.calendar_today_outlined,
                      titulo: 'Dias Analisados',
                      valor: '${_dados!.diasAnalisados}',
                      cor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeletorPeriodo extends StatelessWidget {
  final int diasSelecionado;
  final DateTimeRange? rangeCustom;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustom;

  const _SeletorPeriodo({
    required this.diasSelecionado,
    required this.rangeCustom,
    required this.onChanged,
    required this.onCustom,
  });

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isCustom = rangeCustom != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de análise',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: EagleTokens.inkMute),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _PeriodPill(
                  label: '7d',
                  active: !isCustom && diasSelecionado == 7,
                  onTap: () => onChanged(7),
                ),
                _PeriodPill(
                  label: '30d',
                  active: !isCustom && diasSelecionado == 30,
                  onTap: () => onChanged(30),
                ),
                _PeriodPill(
                  label: '3m',
                  active: !isCustom && diasSelecionado == 90,
                  onTap: () => onChanged(90),
                ),
                _PeriodPill(
                  label: '6m',
                  active: !isCustom && diasSelecionado == 180,
                  onTap: () => onChanged(180),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    isCustom
                        ? '${_fmtDate(rangeCustom!.start)} – ${_fmtDate(rangeCustom!.end)}'
                        : 'Personalizado',
                  ),
                  backgroundColor:
                      isCustom
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                  onPressed: onCustom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              active
                  ? primary
                  : (isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                active
                    ? primary
                    : (isDark ? EagleTokens.darkLine : EagleTokens.line),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ink,
          ),
        ),
      ),
    );
  }
}

class _CardAderencia extends StatelessWidget {
  final AderenciaData dados;

  const _CardAderencia({required this.dados});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxa = dados.taxaAderenciaPercent.clamp(0.0, 100.0);
    final cor =
        taxa >= 75
            ? EagleTokens.good
            : taxa >= 50
            ? EagleTokens.warn
            : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Taxa de Aderência', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _AderenciaRingPainter(
                      fraction: taxa / 100,
                      color: cor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${taxa.toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: cor,
                        ),
                      ),
                      Text(
                        _labelAderencia(taxa),
                        style: theme.textTheme.bodySmall?.copyWith(color: cor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelAderencia(double taxa) {
    if (taxa >= 75) return 'Excelente';
    if (taxa >= 50) return 'Regular';
    return 'Baixa';
  }
}

class _AderenciaRingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _AderenciaRingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 54.0;
    const sw = 14.0;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFE4E5E7)
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AderenciaRingPainter old) => old.fraction != fraction;
}

class _CardInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color cor;

  const _CardInfo({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: EagleTokens.inkMute,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardComparativo extends StatelessWidget {
  final ComparativoPeriodo comparativo;

  const _CardComparativo({required this.comparativo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = comparativo.deltaPercent;
    final isPositivo = delta >= 0;
    final deltaColor = isPositivo ? EagleTokens.good : EagleTokens.bad;
    final deltaIcon = isPositivo ? Icons.arrow_upward : Icons.arrow_downward;
    final deltaText =
        isPositivo
            ? '+${delta.toStringAsFixed(1)}%'
            : '${delta.toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vs. período anterior',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Este período',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EagleTokens.inkMute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAtual.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAtual} check-ins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EagleTokens.inkMute,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deltaIcon, color: deltaColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        deltaText,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Anterior',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EagleTokens.inkMute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAnterior.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EagleTokens.inkMute,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAnterior} check-ins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EagleTokens.inkMute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

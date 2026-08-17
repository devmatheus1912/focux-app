import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/alunos/widgets/aluno_outreach_message_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';
import '../../alunos/constants/aluno_360_layout.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

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
          _erro = friendlyError(e);
          _carregando = false;
        });
      }
    }
  }

  String _periodoLabelPdf() {
    if (_rangeCustom != null) {
      final s = _rangeCustom!.start;
      final e = _rangeCustom!.end;
      return '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}/${s.year} – ${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}/${e.year}';
    }
    return '$_dias dias';
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
                'Período Analisado: ${_periodoLabelPdf()}',
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
    final chrome = ShellChrome.of(context);

    return fxScreenA11yScope(
      label: 'Relatório — ${widget.alunoNome}',
      child: FxShellScaffold(
        constrainWidth: false,
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Relatório',
          subtitle: widget.alunoNome,
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            Semantics(
              label: 'Exportar relatório em PDF',
              button: true,
              child: IconButton(
                tooltip: 'Exportar PDF',
                onPressed: _dados != null ? _exportarPdf : null,
                icon: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: chrome.ink.withValues(alpha: 0.75),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: RefreshIndicator(
            onRefresh: _carregarDados,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TokensStrip.s4),
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
                    const SkeletonList(count: 4)
                  else if (_erro != null)
                    SizedBox(
                      height: 280,
                      child: FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: theme.colorScheme.primary,
                        message: _erro!,
                        onRetry: _carregarDados,
                        title: 'Não conseguimos carregar o relatório',
                      ),
                    )
                  else if (_dados != null && _dados!.treinosTotal == 0)
                    FxEmptyState(
                      icon: 'article',
                      title: 'Sem dados neste período',
                      subtitle:
                          'Quando ${satelliteFirstName(widget.alunoNome)} concluir treinos, o relatório aparece aqui.',
                      action: FxEmptyAction(
                        label: 'Atualizar',
                        onTap: _carregarDados,
                      ),
                    )
                  else if (_dados != null) ...[
                    _CardAderencia(
                      dados: _dados!,
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    if (_comparativo != null) ...[
                      _CardComparativo(comparativo: _comparativo!),
                      const SizedBox(height: TokensStrip.s4),
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
          ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: primary),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de análise',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TokensStrip.textSecondary,
              ),
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              active
                  ? primary
                  : (isDark
                      ? EagleTokens.darkCardHi
                      : TokensStrip.borderDefault),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                active
                    ? primary
                    : (isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault),
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
  final int alunoId;
  final String alunoNome;

  const _CardAderencia({
    required this.dados,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final taxa = dados.taxaAderenciaPercent.clamp(0.0, 100.0);
    final showCheckinCta = taxa < 50;
    final firstName = satelliteFirstName(alunoNome, fallback: 'aluno');
    final cor =
        taxa >= 75
            ? EagleTokens.good
            : taxa >= 50
            ? EagleTokens.warn
            : theme.colorScheme.error;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: cor),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s5),
        child: Column(
          children: [
            Text('Taxa de Aderência', style: theme.textTheme.titleMedium),
            const SizedBox(height: TokensStrip.s5),
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
                      trackColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? EagleTokens.darkLine
                              : TokensStrip.borderDefault,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${taxa.toInt()}%',
                        style: AppTypography.inter(
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
            if (showCheckinCta) ...[
              const SizedBox(height: TokensStrip.s4),
              Text(
                taxa <= 0
                    ? 'Nenhum check-in no período — vale retomar contato com $firstName.'
                    : 'Aderência abaixo do ideal — reforce o hábito de check-in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      () => showAlunoCheckinMessageSheet(
                        context,
                        alunoId: alunoId,
                        alunoNome: alunoNome,
                      ),
                  icon: const Icon(Icons.message_outlined, size: 16),
                  label: const Text('Pedir check-in'),
                  style: Aluno360Layout.operacaoOutlinedButtonStyle(
                    context,
                    primary,
                  ),
                ),
              ),
            ],
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
  final Color trackColor;

  const _AderenciaRingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 54.0;
    const sw = 14.0;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = trackColor
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
  bool shouldRepaint(_AderenciaRingPainter old) =>
      old.fraction != fraction || old.trackColor != trackColor;
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
    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: cor),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
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
                color: TokensStrip.textSecondary,
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

    final primaryAccent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: primaryAccent),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
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
                        color: TokensStrip.textSecondary,
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
                        color: TokensStrip.textSecondary,
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
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAnterior.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAnterior} check-ins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TokensStrip.textSecondary,
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

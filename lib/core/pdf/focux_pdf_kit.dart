import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/focux_official_logo.dart';

/// Paleta dos PDFs (espelha EagleTokens navy / azul petróleo).
abstract final class FocuxPdfColors {
  static const navy = PdfColor.fromInt(0xFF0B1524);
  static const brand = PdfColor.fromInt(0xFF0B4F5C);
  static const brandDeep = PdfColor.fromInt(0xFF083D47);
  static const brandSoft = PdfColor.fromInt(0xFFEBF4F6);
  static const ink = PdfColor.fromInt(0xFF1A1A2E);
  static const mute = PdfColor.fromInt(0xFF6B7280);
  static const line = PdfColor.fromInt(0xFFE5E7EB);
  static const paper = PdfColor.fromInt(0xFFF4F6F8);
  static const zebra = PdfColor.fromInt(0xFFF8F9FA);
  static const good = PdfColor.fromInt(0xFF1B8C54);
  static const bad = PdfColor.fromInt(0xFFC73A3A);
}

/// Fontes com acentuação completa + logo oficial.
class FocuxPdfAssets {
  const FocuxPdfAssets({required this.regular, required this.bold, this.logo});

  final pw.Font regular;
  final pw.Font bold;
  final pw.MemoryImage? logo;

  static Future<FocuxPdfAssets> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final regular = await b.load('assets/google_fonts/Inter-Regular.ttf');
    final bold = await b.load('assets/google_fonts/Inter-Bold.ttf');
    pw.MemoryImage? logo;
    try {
      final bytes = await b.load(FocuxOfficialLogo.assetLight);
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }
    return FocuxPdfAssets(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
      logo: logo,
    );
  }
}

/// Marca do documento: Focux ou a marca própria do personal.
class FocuxPdfBrand {
  const FocuxPdfBrand({
    required this.nome,
    this.cor = FocuxPdfColors.brand,
    this.whiteLabel = false,
  });

  factory FocuxPdfBrand.focux() => const FocuxPdfBrand(nome: 'Focux');

  /// White-label só quando há nome; senão volta para Focux.
  factory FocuxPdfBrand.from({String? nomeMarca, bool ocultarFocux = false}) {
    final nome = (nomeMarca ?? '').trim();
    if (!ocultarFocux || nome.isEmpty) return FocuxPdfBrand.focux();
    return FocuxPdfBrand(nome: nome, whiteLabel: true);
  }

  final String nome;
  final PdfColor cor;
  final bool whiteLabel;

  String get cabecalho => nome.toUpperCase();
  String get rodape => whiteLabel ? nome : 'focux.app';
}

pw.ThemeData focuxPdfTheme(FocuxPdfAssets a) =>
    pw.ThemeData.withFont(base: a.regular, bold: a.bold);

const _corpo = pw.TextStyle(fontSize: 10, color: FocuxPdfColors.ink, lineSpacing: 2);
const _mudo = pw.TextStyle(fontSize: 8.5, color: FocuxPdfColors.mute, lineSpacing: 1.5);

String focuxPdfGeradoLabel(DateTime d) {
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
}

/// Página A4 com cabeçalho em todas as folhas e rodapé "Página x de y".
pw.MultiPage focuxPdfPage({
  required FocuxPdfAssets assets,
  required FocuxPdfBrand brand,
  required String titulo,
  String? subtitulo,
  List<String> linhasMeta = const [],
  required String geradoLabel,
  String? disclaimer,
  required List<pw.Widget> Function(pw.Context) build,
}) {
  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    theme: focuxPdfTheme(assets),
    margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
    header: (ctx) => ctx.pageNumber == 1
        ? _capa(assets, brand, titulo, subtitulo, linhasMeta)
        : pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: FocuxPdfColors.line)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  subtitulo == null ? titulo : '$titulo · $subtitulo',
                  style: _mudo,
                ),
                pw.Text(
                  brand.cabecalho,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: brand.cor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
    footer: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 10),
        if (disclaimer != null && disclaimer.trim().isNotEmpty) ...[
          pw.Text(disclaimer, style: _mudo),
          pw.SizedBox(height: 6),
        ],
        pw.Container(height: 0.6, color: FocuxPdfColors.line),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Gerado em $geradoLabel', style: _mudo),
            pw.Text(
              '${brand.rodape} · página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: _mudo,
            ),
          ],
        ),
      ],
    ),
    build: build,
  );
}

pw.Widget _capa(
  FocuxPdfAssets assets,
  FocuxPdfBrand brand,
  String titulo,
  String? subtitulo,
  List<String> linhasMeta,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 18),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    brand.cabecalho,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: brand.cor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: FocuxPdfColors.navy,
                    ),
                  ),
                  if (subtitulo != null && subtitulo.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      subtitulo,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: FocuxPdfColors.brandDeep,
                      ),
                    ),
                  ],
                  for (final linha in linhasMeta) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(linha, style: const pw.TextStyle(fontSize: 9.5, color: FocuxPdfColors.mute)),
                  ],
                ],
              ),
            ),
            if (!brand.whiteLabel && assets.logo != null)
              pw.SizedBox(height: 30, child: pw.Image(assets.logo!)),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 2, color: brand.cor),
      ],
    ),
  );
}

/// Título + conteúdo como lista solta, para o MultiPage quebrar entre páginas.
List<pw.Widget> focuxPdfSection(String titulo, List<pw.Widget> children) {
  return [
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(width: 3, height: 12, color: FocuxPdfColors.brand),
          pw.SizedBox(width: 6),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: FocuxPdfColors.navy,
            ),
          ),
        ],
      ),
    ),
    ...children,
    pw.SizedBox(height: 16),
  ];
}
pw.Widget focuxPdfKpiRow(List<({String titulo, String valor, String? legenda})> kpis) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < kpis.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 10),
        pw.Expanded(child: _kpi(kpis[i])),
      ],
    ],
  );
}

pw.Widget _kpi(({String titulo, String valor, String? legenda}) k) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: FocuxPdfColors.paper,
      border: pw.Border.all(color: FocuxPdfColors.line),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: 24, height: 3, color: FocuxPdfColors.brand),
        pw.SizedBox(height: 8),
        pw.Text(
          k.valor,
          style: pw.TextStyle(
            fontSize: 17,
            fontWeight: pw.FontWeight.bold,
            color: FocuxPdfColors.navy,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(k.titulo, style: const pw.TextStyle(fontSize: 9, color: FocuxPdfColors.mute)),
        if (k.legenda != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(k.legenda!, style: _mudo),
        ],
      ],
    ),
  );
}

pw.Widget focuxPdfTable({
  required List<String> headers,
  required List<List<String>> rows,
  Map<int, pw.TableColumnWidth>? columnWidths,
  Map<int, pw.Alignment>? cellAlignments,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    ),
    headerDecoration: const pw.BoxDecoration(color: FocuxPdfColors.brand),
    cellStyle: _corpo,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    oddRowDecoration: const pw.BoxDecoration(color: FocuxPdfColors.zebra),
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: FocuxPdfColors.line, width: 0.5),
    ),
    columnWidths: columnWidths,
    cellAlignments: cellAlignments ?? const {},
  );
}

/// Barras horizontais (0..max), uma por linha.
pw.Widget focuxPdfBarChart(
  List<({String label, double valor})> barras, {
  double max = 100,
  String Function(double)? formatar,
}) {
  final fmt = formatar ?? (v) => v.toStringAsFixed(0);
  return pw.Column(
    children: [
      for (final b in barras)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 90, child: pw.Text(b.label, style: _corpo)),
              pw.Expanded(
                child: pw.LayoutBuilder(
                  builder: (ctx, c) {
                    final largura = c!.maxWidth;
                    final frac = max <= 0 ? 0.0 : (b.valor / max).clamp(0.0, 1.0);
                    return pw.Stack(
                      children: [
                        pw.Container(
                          height: 10,
                          width: largura,
                          decoration: const pw.BoxDecoration(
                            color: FocuxPdfColors.paper,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                          ),
                        ),
                        pw.Container(
                          height: 10,
                          width: largura * frac,
                          decoration: const pw.BoxDecoration(
                            color: FocuxPdfColors.brand,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              pw.SizedBox(
                width: 44,
                child: pw.Text(
                  fmt(b.valor),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: FocuxPdfColors.navy),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

List<(String, String)> focuxPdfParesPreenchidos(List<(String, String)> pares) => [
  for (final p in pares)
    if (p.$2.trim().isNotEmpty && p.$2.trim() != '—') p,
];

/// Rótulo/valor em duas colunas; pula vazios.
List<pw.Widget> focuxPdfFieldPairs(List<(String, String)> pares) {
  final cheios = focuxPdfParesPreenchidos(pares);
  if (cheios.isEmpty) return [pw.Text('Nada preenchido.', style: _mudo)];
  return [
    for (var i = 0; i < cheios.length; i++)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        color: i.isEven ? FocuxPdfColors.zebra : null,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(
                cheios[i].$1,
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: FocuxPdfColors.mute),
              ),
            ),
            pw.Expanded(child: pw.Text(cheios[i].$2, style: _corpo)),
          ],
        ),
      ),
  ];
}
/// Caixa de destaque (alertas, resumo).
pw.Widget focuxPdfCallout(String texto, {bool alerta = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: alerta ? const PdfColor.fromInt(0xFFFDECEC) : FocuxPdfColors.brandSoft,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Text(
      texto,
      style: pw.TextStyle(fontSize: 10, color: alerta ? FocuxPdfColors.bad : FocuxPdfColors.ink),
    ),
  );
}

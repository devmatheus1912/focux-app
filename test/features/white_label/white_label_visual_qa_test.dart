import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final scenario in _brandScenarios) {
    test(
      'white-label screenshot QA renders ${scenario.name} without legacy blue',
      () async {
        final image = await _drawQaContactSheet(scenario);
        final rawData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();

        final raw = rawData!.buffer.asUint8List();
        final output = File(
          'build/white_label_visual_qa/${scenario.fileName}.png',
        );
        await output.parent.create(recursive: true);
        await output.writeAsBytes(pngData!.buffer.asUint8List());

        expect(_exactColorCount(raw, scenario.primary), greaterThan(1200));
        expect(_exactColorCount(raw, const Color(0xFF2563EB)), 0);
        expect(_exactColorCount(raw, const Color(0xFF0288D1)), 0);
      },
    );
  }

  test('primary foreground stays readable for extreme white-label colors', () {
    for (final scenario in _brandScenarios) {
      final theme = AppTheme.buildTheme(scenario.primary);
      final contrast = _contrastRatio(
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      );

      expect(contrast, greaterThanOrEqualTo(4.5), reason: scenario.name);
    }
  });

  test('dark theme remaps atmosphere primaries so chrome reads on mesh', () {
    for (final palette in CuratedBrandPalette.premium) {
      final theme = AppTheme.buildDarkTheme(
        palette.primary,
        secondary: palette.secondary,
      );
      expect(
        FocuxContrast.contrastRatio(
          theme.colorScheme.primary,
          EagleTokens.darkBg,
        ),
        greaterThanOrEqualTo(FocuxContrast.wcagAaLarge),
        reason: palette.name,
      );
    }
    final midnight = AppTheme.buildDarkTheme(
      const Color(0xFF1A2332),
      secondary: const Color(0xFFC9A962),
    );
    expect(midnight.colorScheme.primary, isNot(const Color(0xFF1A2332)));
  });

  test('AuthShell forceDark re-wrap keeps brand gold, not Focux default', () {
    for (final palette in CuratedBrandPalette.premium) {
      if (palette.id == CuratedBrandPalette.focuxDefault.id) continue;
      final first = AppTheme.buildDarkTheme(
        palette.primary,
        secondary: palette.secondary,
      );
      // AuthShell / FxHomeSheet passam colorScheme de volta ao tema.
      final second = AppTheme.buildDarkTheme(
        first.colorScheme.primary,
        secondary: first.colorScheme.secondary,
      );
      expect(
        second.colorScheme.secondary,
        first.colorScheme.secondary,
        reason: '${palette.name} secondary after AuthShell wrap',
      );
      expect(
        second.colorScheme.secondary,
        isNot(BrandPalette.defaultSecondary),
        reason: '${palette.name} must not snap to Focux default',
      );
      expect(
        second.colorScheme.primary,
        isNot(BrandPalette.defaultPrimary),
        reason: '${palette.name} must not snap to Focux petroleum default',
      );
    }
  });
}

class _BrandScenario {
  const _BrandScenario({
    required this.name,
    required this.fileName,
    required this.primary,
  });

  final String name;
  final String fileName;
  final Color primary;
}

const _brandScenarios = [
  _BrandScenario(
    name: 'light gold',
    fileName: '01_light_gold',
    primary: Color(0xFFF2C94C),
  ),
  _BrandScenario(
    name: 'deep graphite',
    fileName: '02_deep_graphite',
    primary: Color(0xFF101827),
  ),
  _BrandScenario(
    name: 'saturated rose',
    fileName: '03_saturated_rose',
    primary: Color(0xFFD81B60),
  ),
];

Future<ui.Image> _drawQaContactSheet(_BrandScenario scenario) async {
  final theme = AppTheme.buildTheme(scenario.primary);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(390, 844);
  final primary = theme.colorScheme.primary;
  final onPrimary = theme.colorScheme.onPrimary;
  final surface = theme.colorScheme.surface;
  final background = theme.scaffoldBackgroundColor;

  canvas.drawRect(Offset.zero & size, Paint()..color = background);
  _drawHeader(canvas, theme, scenario.name);

  var top = 96.0;
  top = _drawPanel(
    canvas,
    theme,
    top: top,
    title: 'Auth',
    icon: Icons.lock_outline,
    primary: primary,
    onPrimary: onPrimary,
    rows: const ['Email do personal', 'Entrar com identidade visual'],
  );
  top = _drawPanel(
    canvas,
    theme,
    top: top,
    title: 'Dashboard',
    icon: Icons.dashboard_outlined,
    primary: primary,
    onPrimary: onPrimary,
    rows: const ['Alunos ativos 48', 'Check-ins hoje 12', 'Riscos 3'],
  );
  top = _drawPanel(
    canvas,
    theme,
    top: top,
    title: 'Chat iPhone-like',
    icon: Icons.chat_bubble_outline,
    primary: primary,
    onPrimary: onPrimary,
    rows: const ['Treino ajustado para hoje', 'Audio, emoji e midia'],
  );
  top = _drawPanel(
    canvas,
    theme,
    top: top,
    title: 'Treinos',
    icon: Icons.fitness_center,
    primary: primary,
    onPrimary: onPrimary,
    rows: const ['Treino A 45 min', 'Video do personal'],
  );
  _drawPanel(
    canvas,
    theme,
    top: top,
    title: 'Marca premium',
    icon: Icons.public,
    primary: primary,
    onPrimary: onPrimary,
    rows: const ['Servicos e valores', 'Foto principal'],
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 768, 390, 76),
      const Radius.circular(28),
    ),
    Paint()..color = surface.withValues(alpha: 0.96),
  );
  _drawCircle(canvas, const Offset(195, 806), 18, primary);
  _drawText(canvas, 'IA', const Offset(185, 800), 12, onPrimary, bold: true);

  final picture = recorder.endRecording();
  return picture.toImage(size.width.toInt(), size.height.toInt());
}

void _drawHeader(Canvas canvas, ThemeData theme, String label) {
  final primary = theme.colorScheme.primary;
  final onPrimary = theme.colorScheme.onPrimary;

  canvas.drawRect(
    const Rect.fromLTWH(20, 20, 54, 54),
    Paint()..color = primary,
  );
  _drawText(canvas, 'F', const Offset(37, 32), 24, onPrimary, bold: true);
  _drawText(
    canvas,
    'QA white-label',
    const Offset(88, 24),
    20,
    theme.colorScheme.onSurface,
    bold: true,
  );
  _drawText(
    canvas,
    label,
    const Offset(88, 50),
    13,
    theme.colorScheme.onSurfaceVariant,
  );
  _drawButton(
    canvas,
    'Ativo',
    const Rect.fromLTWH(300, 26, 70, 42),
    primary,
    onPrimary,
  );
}

double _drawPanel(
  Canvas canvas,
  ThemeData theme, {
  required double top,
  required String title,
  required IconData icon,
  required Color primary,
  required Color onPrimary,
  required List<String> rows,
}) {
  final rect = Rect.fromLTWH(16, top, 358, 116);
  final surface = theme.colorScheme.surface;
  final outline = theme.colorScheme.outline;
  final soft = theme.colorScheme.primaryContainer;

  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(EagleTokens.radiusLg)),
    Paint()..color = surface,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(EagleTokens.radiusLg)),
    Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  _drawCircle(canvas, Offset(40, top + 28), 16, soft);
  _drawIcon(canvas, icon, Offset(31, top + 19), 18, primary);
  _drawText(
    canvas,
    title,
    Offset(66, top + 19),
    15,
    theme.colorScheme.onSurface,
    bold: true,
  );

  var rowTop = top + 52;
  for (final row in rows) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, rowTop, 210, 24),
        const Radius.circular(8),
      ),
      Paint()..color = soft,
    );
    _drawText(
      canvas,
      row,
      Offset(40, rowTop + 5),
      11,
      theme.colorScheme.onSurface,
    );
    rowTop += 30;
  }

  _drawButton(
    canvas,
    'Abrir',
    Rect.fromLTWH(276, top + 58, 70, 38),
    primary,
    onPrimary,
  );

  return top + 130;
}

void _drawButton(
  Canvas canvas,
  String label,
  Rect rect,
  Color color,
  Color textColor,
) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(EagleTokens.radiusSm)),
    Paint()..color = color,
  );
  _drawText(
    canvas,
    label,
    Offset(rect.left + 16, rect.top + 12),
    12,
    textColor,
    bold: true,
  );
}

void _drawCircle(Canvas canvas, Offset center, double radius, Color color) {
  canvas.drawCircle(center, radius, Paint()..color = color);
}

void _drawIcon(
  Canvas canvas,
  IconData icon,
  Offset offset,
  double size,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        inherit: false,
        color: color,
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, offset);
}

void _drawText(
  Canvas canvas,
  String text,
  Offset offset,
  double size,
  Color color, {
  bool bold = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        inherit: false,
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontFamily: bold ? 'Space Grotesk' : 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: 260);
  painter.paint(canvas, offset);
}

int _exactColorCount(Uint8List bytes, Color color) {
  final expected = _rgba(color);
  var count = 0;

  for (var offset = 0; offset < bytes.length; offset += 4) {
    if (bytes[offset] == expected[0] &&
        bytes[offset + 1] == expected[1] &&
        bytes[offset + 2] == expected[2] &&
        bytes[offset + 3] == expected[3]) {
      count++;
    }
  }

  return count;
}

List<int> _rgba(Color color) {
  final value = color.toARGB32();
  return [
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

double _contrastRatio(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

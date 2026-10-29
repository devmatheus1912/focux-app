import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/brand_style.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/identidade_visual_display.dart';

/// Três miniaturas do card principal, uma por estilo: o personal vê a
/// diferença em vez de ler uma descrição. A escolhida ganha contorno e marca.
class IdentidadeEstiloMiniaturas extends StatelessWidget {
  const IdentidadeEstiloMiniaturas({
    super.key,
    required this.selecionado,
    required this.primaria,
    required this.onSelecionar,
    this.dark = false,
  });

  final BrandStyle selecionado;
  final Color primaria;
  final ValueChanged<BrandStyle>? onSelecionar;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, e) in BrandStyle.values.indexed) ...[
          if (i > 0) const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: _Miniatura(
              estilo: e,
              selecionado: e == selecionado,
              primaria: primaria,
              dark: dark,
              onTap:
                  onSelecionar == null
                      ? null
                      : () {
                        HapticFeedback.selectionClick();
                        onSelecionar!(e);
                      },
            ),
          ),
        ],
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.estilo,
    required this.selecionado,
    required this.primaria,
    required this.dark,
    required this.onTap,
  });

  final BrandStyle estilo;
  final bool selecionado;
  final Color primaria;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final nome = identidadeEstiloLabel(estilo);
    return Semantics(
      button: true,
      selected: selecionado,
      label: 'Estilo $nome',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(TokensStrip.s2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(
              color: selecionado ? primaria : chrome.lineStrong,
              width: selecionado ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: CustomPaint(
                  painter: _MiniCard(
                    estilo: estilo,
                    primaria: primaria,
                    dark: dark,
                    linha: chrome.mute,
                    contorno: chrome.lineStrong,
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selecionado) ...[
                    Icon(Icons.check_circle_rounded, size: 14, color: primaria),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.chip(
                        selecionado ? primaria : chrome.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenho do mini card: mostra só a diferença entre os estilos.
class _MiniCard extends CustomPainter {
  const _MiniCard({
    required this.estilo,
    required this.primaria,
    required this.dark,
    required this.linha,
    required this.contorno,
  });

  final BrandStyle estilo;
  final Color primaria;
  final bool dark;
  final Color linha;
  final Color contorno;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final solido = estilo.cardSolido
        ? BrandPalette.cardDeMarca(primaria, dark: dark)
        : null;
    final tinta = solido?.sobre ?? linha;

    if (solido != null) {
      canvas.drawRRect(
        r,
        Paint()
          ..shader = solido.degrade.createShader(Offset.zero & size),
      );
    } else if (estilo == BrandStyle.classico) {
      canvas.drawRRect(
        r,
        Paint()..color = dark ? EagleTokens.darkCard : Colors.white,
      );
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = contorno,
      );
      // barra da marca na lateral
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, 5, size.height),
          topLeft: const Radius.circular(10),
          bottomLeft: const Radius.circular(10),
        ),
        Paint()..color = primaria,
      );
    } else {
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = contorno,
      );
    }

    final px = size.width * 0.14;
    Paint barra(double a, [Color? cor]) =>
        Paint()..color = (cor ?? tinta).withValues(alpha: a);
    void linhaBarra(double y, double largura, Paint p) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px, y, size.width * largura, size.height * 0.07),
        const Radius.circular(3),
      ),
      p,
    );

    // título e subtítulo
    linhaBarra(
      size.height * 0.2,
      0.5,
      barra(
        0.9,
        estilo == BrandStyle.minimalista ? primaria : null,
      ),
    );
    linhaBarra(size.height * 0.36, 0.34, barra(0.45));
    // botão
    final botao = RRect.fromRectAndRadius(
      Rect.fromLTWH(px, size.height * 0.62, size.width - px * 2, size.height * 0.22),
      const Radius.circular(8),
    );
    if (solido != null) {
      canvas.drawRRect(botao, Paint()..color = solido.sobre);
    } else if (estilo == BrandStyle.classico) {
      canvas.drawRRect(botao, Paint()..color = primaria);
    } else {
      canvas.drawRRect(
        botao,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = primaria,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniCard old) =>
      old.estilo != estilo ||
      old.primaria != primaria ||
      old.dark != dark ||
      old.linha != linha;
}

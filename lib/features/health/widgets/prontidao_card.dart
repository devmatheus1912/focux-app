import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../data/health_repository.dart';
import '../utils/health_plausibilidade.dart';
import '../utils/prontidao_display.dart';

/// Card da nota de prontidão, na cor da marca (mesmo princípio do card
/// principal da Home). Três estados com a mesma altura: com nota, sem sono e
/// calibrando.
class ProntidaoCard extends StatelessWidget {
  const ProntidaoCard({
    super.key,
    required this.recovery,
    required this.onPorQue,
    required this.onVerTreino,
    required this.onComoRegistrar,
    this.onAtualizar,
    this.sonoLocal = false,
  });

  final RecoverySnapshot? recovery;

  /// O aparelho tem sono hoje, mas a nota não veio do servidor.
  final bool sonoLocal;
  final VoidCallback? onAtualizar;
  final VoidCallback onPorQue;
  final VoidCallback onVerTreino;
  final VoidCallback onComoRegistrar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final marca = BrandPalette.cardDeMarca(primary, dark: chrome.isDark);
    final estado = prontidaoEstado(recovery, sonoLocal: sonoLocal);
    final score = recovery?.recoveryScore;

    final String titulo;
    final String texto;
    switch (estado) {
      case ProntidaoEstado.comNota:
        titulo = recovery!.recoveryLabel;
        texto = '${recovery!.recoveryHint}\n${dicaDoTreino(score!)}';
      case ProntidaoEstado.calibrando:
        titulo = 'Calibrando sua nota';
        texto =
            'Com alguns dias de sono registrado, a nota aparece e passa a '
            'comparar você com a sua própria média.';
      case ProntidaoEstado.indisponivel:
        titulo = 'Prontidão indisponível';
        texto =
            'Não sincronizamos com o servidor agora. Puxe a tela para baixo '
            'ou toque em atualizar.';
      case ProntidaoEstado.semSono:
        titulo = 'Sem sono registrado';
        texto =
            'Sem o sono não calculamos sua prontidão. Use o relógio para '
            'dormir ou registre o sono no app Saúde.';
    }

    return Semantics(
      container: true,
      label:
          estado == ProntidaoEstado.comNota
              ? 'Prontidão de hoje: nota $score de 100, $titulo'
              : 'Prontidão de hoje: $titulo',
      child: Container(
        constraints: const BoxConstraints(minHeight: 232),
        padding: const EdgeInsets.all(TokensStrip.s5),
        decoration: BoxDecoration(
          gradient: marca.degrade,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prontidão de hoje',
              style: TextStyle(
                color: marca.sobre.withValues(alpha: 0.82),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProntidaoAnel(
                  score: score,
                  cor: marca.sobre,
                  icone:
                      estado == ProntidaoEstado.calibrando
                          ? Icons.hourglass_bottom_rounded
                          : estado == ProntidaoEstado.indisponivel
                          ? Icons.cloud_off_rounded
                          : Icons.bedtime_outlined,
                ),
                const SizedBox(width: TokensStrip.s4),
                Expanded(
                  child: Text(
                    titulo,
                    style: FocuxHubTypography.body(color: marca.sobre)
                        .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensStrip.s3),
            Text(
              texto,
              style: TextStyle(
                color: marca.sobre.withValues(alpha: 0.92),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                if (estado == ProntidaoEstado.comNota) ...[
                  _BotaoDoCard(
                    rotulo: 'Ver treino de hoje',
                    icone: Icons.fitness_center_rounded,
                    cheio: true,
                    marca: marca,
                    onTap: onVerTreino,
                  ),
                  _BotaoDoCard(
                    rotulo: 'Por quê?',
                    icone: Icons.info_outline_rounded,
                    marca: marca,
                    onTap: onPorQue,
                  ),
                ] else if (estado == ProntidaoEstado.indisponivel)
                  _BotaoDoCard(
                    rotulo: 'Atualizar',
                    icone: Icons.refresh_rounded,
                    cheio: true,
                    marca: marca,
                    onTap: onAtualizar ?? onComoRegistrar,
                  )
                else if (estado == ProntidaoEstado.calibrando)
                  _BotaoDoCard(
                    rotulo: 'Por quê?',
                    icone: Icons.info_outline_rounded,
                    cheio: true,
                    marca: marca,
                    onTap: onPorQue,
                  )
                else
                  _BotaoDoCard(
                    rotulo: 'Como registrar',
                    icone: Icons.bedtime_outlined,
                    cheio: true,
                    marca: marca,
                    onTap: onComoRegistrar,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Anel grande da nota. O traço enche e o número sobe até o valor; com "reduzir
/// movimento" entra direto.
class ProntidaoAnel extends StatelessWidget {
  const ProntidaoAnel({
    super.key,
    required this.score,
    required this.cor,
    required this.icone,
    this.tamanho = 104,
  });

  final int? score;
  final Color cor;
  final IconData icone;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final reduzir = TokensStrip.prefersReducedMotion(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score ?? 0).toDouble()),
        duration: reduzir ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, valor, _) {
          return SizedBox(
            width: tamanho,
            height: tamanho,
            child: CustomPaint(
              painter: _AnelPainter(valor: score == null ? null : valor, cor: cor),
              child: Center(
                child:
                    score == null
                        ? Icon(icone, color: cor, size: tamanho * 0.36)
                        : Text(
                          valor.round().toString(),
                          style: TextStyle(
                            color: cor,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  _AnelPainter({required this.valor, required this.cor});

  final double? valor;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.width / 2 - 6;
    final fundo =
        Paint()
          ..color = cor.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, raio, fundo);
    final v = valor;
    if (v == null) return;
    final traco =
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      (v.clamp(0, prontidaoEscalaMax) / prontidaoEscalaMax) * math.pi * 2,
      false,
      traco,
    );
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) =>
      old.valor != valor || old.cor != cor;
}

class _BotaoDoCard extends StatelessWidget {
  const _BotaoDoCard({
    required this.rotulo,
    required this.icone,
    required this.marca,
    required this.onTap,
    this.cheio = false,
  });

  final String rotulo;
  final IconData icone;
  final CardDeMarca marca;
  final VoidCallback onTap;
  final bool cheio;

  @override
  Widget build(BuildContext context) {
    final fundo = cheio ? marca.sobre : marca.sobre.withValues(alpha: 0.16);
    final texto = cheio ? marca.fundo : marca.sobre;
    return Semantics(
      button: true,
      label: rotulo,
      excludeSemantics: true,
      child: Material(
        color: fundo,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 18, color: texto),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: texto,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

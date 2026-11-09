import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/fx_tonal_button.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../data/health_repository.dart';
import '../utils/health_plausibilidade.dart';
import '../utils/prontidao_display.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_action_link.dart';

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
        final feitas = recovery?.noitesNaBase ?? 0;
        final total = recovery?.noitesParaCalibrar ?? 5;
        titulo = 'Calibrando sua nota · $feitas de $total noites';
        texto =
            'A nota compara a sua noite com as suas últimas noites. Com '
            '$total noites registradas ela aparece.';
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

    // Sem sono, nada a calcular ainda: linha discreta no fundo da tela, não o
    // cartão da marca (o bloco "Sono" do resumo leva ao mesmo "Como registrar").
    if (estado == ProntidaoEstado.semSono) {
      return Semantics(
        container: true,
        label: 'Prontidão de hoje: sua nota sai com o sono da noite',
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s2,
            TokensStrip.s2,
            TokensStrip.s2,
          ),
          decoration: BoxDecoration(
            color: chrome.cardFill,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(color: chrome.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s2),
                child: Icon(FxIcons.sono, color: chrome.mute, size: 20),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      'Sua nota sai com o sono da noite',
                      style: FocuxHubTypography.bodyMuted(color: chrome.ink),
                    ),
                    FxActionLink(
                      label: 'Como registrar',
                      onTap: onComoRegistrar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sem nota, uma faixa de uma linha: o anel vazio parecia "carregando" ou
    // "nota zero" e empurrava os dados do dia para baixo da dobra.
    if (estado != ProntidaoEstado.comNota) {
      final (rotulo, icone, acao) = switch (estado) {
        ProntidaoEstado.calibrando => ('Por quê?', FxIcons.ampulheta, onPorQue),
        ProntidaoEstado.indisponivel => ('Atualizar', FxIcons.semConexao, onAtualizar ?? onComoRegistrar),
        _ => ('Como registrar', FxIcons.sono, onComoRegistrar),
      };
      return Semantics(
        container: true,
        label: 'Prontidão de hoje: $titulo. $texto',
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, TokensStrip.s3, TokensStrip.s3, TokensStrip.s3),
          decoration: BoxDecoration(
            gradient: marca.degrade,
            borderRadius: BorderRadius.circular(20),
          ),
          // Título numa linha e o botão logo abaixo: cabe de 320 dp à letra 2x.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: marca.sobre, size: 22),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.body(color: marca.sobre)
                          .copyWith(fontSize: TokensStrip.fontBody, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                  ),
                ],
              ),
              if (estado == ProntidaoEstado.calibrando) ...[
                const SizedBox(height: TokensStrip.s2),
                // Quantas noites a base já tem.
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rPill),
                  child: LinearProgressIndicator(
                    value: ((recovery?.noitesNaBase ?? 0) /
                            (recovery?.noitesParaCalibrar ?? 5))
                        .clamp(0.0, 1.0),
                    minHeight: 6,
                    color: marca.sobre,
                    backgroundColor: marca.sobre.withValues(alpha: 0.24),
                  ),
                ),
              ],
              const SizedBox(height: TokensStrip.s2),
              _BotaoDoCard(rotulo: rotulo, icone: icone, cheio: true, marca: marca, onTap: acao),
            ],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Prontidão de hoje: nota $score de 100, $titulo',
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
                fontSize: TokensStrip.fontBodySm,
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
                          ? FxIcons.ampulheta
                          : estado == ProntidaoEstado.indisponivel
                          ? FxIcons.semConexao
                          : FxIcons.sono,
                ),
                const SizedBox(width: TokensStrip.s4),
                Expanded(
                  child: Text(
                    titulo,
                    style: FocuxHubTypography.body(color: marca.sobre)
                        .copyWith(
                          fontSize: TokensStrip.fontSecao,
                          fontWeight: FontWeight.w700,
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
                fontSize: TokensStrip.fontBody,
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
                    icone: FxIcons.treino,
                    cheio: true,
                    marca: marca,
                    onTap: onVerTreino,
                  ),
                  _BotaoDoCard(
                    rotulo: 'Por quê?',
                    icone: FxIcons.info,
                    marca: marca,
                    onTap: onPorQue,
                  ),
                ] else if (estado == ProntidaoEstado.indisponivel)
                  _BotaoDoCard(
                    rotulo: 'Atualizar',
                    icone: FxIcons.atualizar,
                    cheio: true,
                    marca: marca,
                    onTap: onAtualizar ?? onComoRegistrar,
                  )
                else if (estado == ProntidaoEstado.calibrando)
                  _BotaoDoCard(
                    rotulo: 'Por quê?',
                    icone: FxIcons.info,
                    cheio: true,
                    marca: marca,
                    onTap: onPorQue,
                  )
                else
                  _BotaoDoCard(
                    rotulo: 'Como registrar',
                    icone: FxIcons.sono,
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
                            fontSize: TokensStrip.fontNumeroTela,
                            fontWeight: FontWeight.w700,
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
    // O secundário tonal do kit, nas cores do card de marca.
    return FxTonalButton(
      label: rotulo,
      icon: icone,
      compact: true,
      fundo: cheio ? marca.sobre : marca.sobre.withValues(alpha: 0.16),
      texto: cheio ? marca.fundo : marca.sobre,
      onPressed: onTap,
    );
  }
}

import 'dart:math' as math;

import '../../../core/widgets/fx_conversion.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';
import '../../../core/theme/fx_icons.dart';

/// RPE gravado (1 a 10) -> o botão rápido mais próximo (4, 6 ou 8).
int? _rpeNoGrupo(int? rpe) {
  if (rpe == null) return null;
  if (rpe <= 5) return 4;
  if (rpe <= 7) return 6;
  return 8;
}

/// S8: um alvo — o tempo. Pular/Trocar são botões tonais na thumb zone.
class CheckinRestFocusView extends StatelessWidget {
  final int seconds;
  final int? totalSeconds;
  final String? contextLine;
  final VoidCallback onSkip;

  /// Número da série que acabou: a pergunta do esforço diz qual é.
  final int? serieAvaliada;

  /// Soma ou tira segundos do descanso (±15 s).
  final ValueChanged<int>? onAjustar;

  /// Esforço da série que acabou (opcional): três toques, sem sair do descanso.
  final ValueChanged<int>? onRpe;
  final int? rpeEscolhido;
  final int? rpeAlvo;

  const CheckinRestFocusView({
    super.key,
    required this.seconds,
    required this.onSkip,
    this.totalSeconds,
    this.contextLine,
    this.serieAvaliada,
    this.onAjustar,
    this.onRpe,
    this.rpeEscolhido,
    this.rpeAlvo,
    this.onAtivarNotificacoes,
  });

  /// Notificações negadas: linha discreta para ativar o aviso com a tela
  /// bloqueada (só no primeiro descanso).
  final VoidCallback? onAtivarNotificacoes;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    final countdown = checkinRestCountdownLabel(seconds);
    final total = totalSeconds;
    final progress =
        total != null && total > 0 ? (seconds / total).clamp(0.0, 1.0) : 1.0;
    final contextText = contextLine?.trim();
    final hasContext = contextText != null && contextText.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s5),
        child: Semantics(
          label: checkinRestSemanticsLabel(
            s,
            seconds: seconds,
            contextLine: contextText,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.checkinDescanso,
                style: FocuxHubTypography.chip(chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s4),
              // Fonte grande: a linha encolhe junto, sem estourar a largura.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAjustar != null) ...[
                      _AjusteDescanso(
                        icone: FxIcons.remover,
                        rotulo: s.checkinDescansoMenos15,
                        leitura: s.checkinDescansoMenos15Leitura,
                        onTap: () => onAjustar!(-15),
                      ),
                      const SizedBox(width: TokensStrip.s3),
                    ],
                    SizedBox(
                      width: checkinRestRingSize,
                      height: checkinRestRingSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ExcludeSemantics(
                            child: CustomPaint(
                              size: const Size.square(checkinRestRingSize),
                              painter: _CheckinRestRingPainter(
                                progress: progress,
                                color: brand,
                                trackColor: chrome.mute.withValues(alpha: 0.14),
                                strokeWidth: TokensStrip.s2,
                              ),
                            ),
                          ),
                          Text(
                            countdown,
                            style: FocuxHubTypography.metric(
                              color: chrome.ink,
                              fontSize: TokensStrip.fontH1,
                              fontWeight: FontWeight.w700,
                            ).copyWith(
                              letterSpacing: TokensStrip.trackingH1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onAjustar != null) ...[
                      const SizedBox(width: TokensStrip.s3),
                      _AjusteDescanso(
                        icone: FxIcons.adicionar,
                        rotulo: s.checkinDescansoMais15,
                        leitura: s.checkinDescansoMais15Leitura,
                        onTap: () => onAjustar!(15),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasContext) ...[
                const SizedBox(height: TokensStrip.s3),
                Text(
                  contextText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
              if (onRpe != null) ...[
                const SizedBox(height: TokensStrip.s4),
                Text(
                  serieAvaliada == null
                      ? s.checkinRpeComoFoi
                      : s.checkinRpeComoFoiN(serieAvaliada!),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                const SizedBox(height: TokensStrip.s2),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final (rotulo, valor) in [
                      (s.checkinRpeLeve, 4),
                      (s.checkinRpeModerado, 6),
                      (s.checkinRpePesado, 8),
                    ])
                      FxToggleChip(
                        label: rotulo,
                        selected: _rpeNoGrupo(rpeEscolhido) == valor,
                        isDark: chrome.isDark,
                        filledWhenSelected: true,
                        onTap: () => onRpe!(valor),
                      ),
                  ],
                ),
                if (rpeAlvo != null) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    s.checkinRpeAlvoCurto(rpeAlvo!),
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
              ],
              if (onAtivarNotificacoes != null) ...[
                const SizedBox(height: TokensStrip.s3),
                FxConversionTextLink(
                  text: s.checkinDescansoNotificacoesNegadas,
                  actionText: s.checkinDescansoAtivarNotificacoes,
                  onTap: onAtivarNotificacoes!,
                ),
              ],
              const SizedBox(height: TokensStrip.s5),
              // Trocar o exercício fica no menu "···" ("Trocar exercício").
              FxTonalButton(
                label: s.checkinPularDescanso,
                icon: FxIcons.proximo,
                expanded: true,
                onPressed: onSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// −15 s / +15 s ao lado do anel: alvo de 48, rótulo curto embaixo.
class _AjusteDescanso extends StatelessWidget {
  const _AjusteDescanso({
    required this.icone,
    required this.rotulo,
    required this.leitura,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;

  /// O que o leitor de tela diz: o ícone (− / +) não é lido.
  final String leitura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Semantics(
      button: true,
      label: leitura,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            onPressed: onTap,
            icon: Icon(icone, size: 20),
            constraints: const BoxConstraints.tightFor(
              width: checkinExecutionControlMin,
              height: checkinExecutionControlMin,
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          ExcludeSemantics(
            child: Text(rotulo, style: FocuxHubTypography.chip(chrome.mute)),
          ),
        ],
      ),
    );
  }
}

class _CheckinRestRingPainter extends CustomPainter {
  const _CheckinRestRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final fill =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (progress.clamp(0.0, 1.0)) * math.pi * 2,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckinRestRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

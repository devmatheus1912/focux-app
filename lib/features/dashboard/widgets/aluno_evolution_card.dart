import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../data/aluno_destaque_exercicio.dart';
import '../utils/aluno_home_texts.dart';
import 'dashboard_section_header.dart';

/// "Evolução": a curva do exercício que o aluno mais treina (1RM estimado) e
/// os recordes do mês. Volume fica em "Sua semana"; o insight, no card de foco.
class AlunoEvolutionCard extends StatelessWidget {
  const AlunoEvolutionCard({
    super.key,
    this.destaque,
    this.ultimoRecorde,
    this.recordesMes = 0,
  });

  final AlunoDestaqueExercicio? destaque;
  final RecordePessoal? ultimoRecorde;
  final int recordesMes;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chrome = ShellChrome.of(context);
    final d = destaque;
    final rodape = alunoRecordesRodape(
      s,
      recordesMes: recordesMes,
      ultimaData: ultimoRecorde?.data,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: s.alunoEvolucaoTitulo),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: fxListCardDecoration(context, accent: scheme.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d == null)
                Text(
                  s.alunoEvolucaoVazio,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                )
              else
                _Destaque(destaque: d, color: scheme.secondary),
              if (rodape != null) ...[
                const SizedBox(height: TokensStrip.s3),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: TokensStrip.s2),
                    Expanded(
                      child: Text(
                        rodape,
                        style: FocuxHubTypography.bodyMuted(
                          color: chrome.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({required this.destaque, required this.color});

  final AlunoDestaqueExercicio destaque;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = destaque;
    final subiu = d.deltaPercent > 0;
    final deltaCor = subiu ? EagleTokens.semanticGood(isDark: isDark) : chrome.mute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          alunoInicialMaiuscula(d.nome),
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: TokensStrip.s1),
        Text(
          d.temCurva
              ? s.alunoEvolucaoCargaDeAte(d.inicialKg, d.atualKg)
              : s.alunoEvolucaoCargaKg(d.atualKg),
          style: FocuxHubTypography.metric(color: chrome.ink, fontSize: 24),
        ),
        const SizedBox(height: TokensStrip.s1),
        if (d.temCurva) ...[
          Text(
            s.alunoEvolucaoDeltaEmSemanas(
              alunoForcaDeltaTexto(s, d.deltaPercent),
              d.semanas,
            ),
            style: FocuxHubTypography.chip(deltaCor),
          ),
          const SizedBox(height: TokensStrip.s3),
          _Sparkline(
            data: d.serieSemanal,
            color: color,
            semanticsLabel: s.alunoEvolucaoCurvaSemantics(
              d.semanas,
              d.nome,
              d.inicialKg,
              d.atualKg,
            ),
          ),
        ] else
          Text(
            s.alunoEvolucaoCurvaEmBreve,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.data,
    required this.color,
    required this.semanticsLabel,
  });

  final List<double> data;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: CustomPaint(painter: _SparklinePainter(data: data, color: color)),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.data, required this.color});

  static const strokeWidth = 2.4;
  static const dotRadius = 3.5;

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    const pad = dotRadius + 1;
    final h = size.height - pad * 2;
    final w = size.width - pad * 2;
    Offset at(int i) => Offset(
      pad + i * w / (data.length - 1),
      pad + h - ((data[i] - minV) / span) * h,
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < data.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    canvas.drawCircle(at(0), dotRadius, dot);
    canvas.drawCircle(at(data.length - 1), dotRadius, dot);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

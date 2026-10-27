import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_week_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_today_action.dart';
import 'aluno_home_insight_line.dart';

/// Card de foco: a única superfície com `emphasize` na Home. Molde único:
/// eyebrow · título · contexto · semana · ação principal · ação secundária.
class AlunoTodayFocusCard extends StatelessWidget {
  final AlunoTodayAction action;
  final DateTime hoje;
  final bool isDark;
  final VoidCallback onAction;
  final VoidCallback? onOpen;
  final AlunoHomeInsight? insight;

  /// Próximo horário de hoje ou amanhã (`alunoHorarioNoFoco`).
  final DateTime? horario;
  final bool prontidaoBaixa;

  /// Semana dentro do card (vazia = sem faixa) e o que o toque nela abre.
  final List<FxWeekDay> semana;
  final VoidCallback? onSemana;

  /// Selo da ficha no canto ("Até 14/02", "Atualizada").
  final String? seloFicha;
  final FxPillTone seloFichaTom;

  /// "Ver o treino" no descanso: abre a aba Treinos.
  final VoidCallback? onVerTreinos;

  /// Fundo com a marca (gradiente sutil); nulo mantém o card atual.
  final Gradient? fundoMarca;

  /// Nome do personal: vira "Treino com {Personal}" no eyebrow do treino pronto.
  final String? assinatura;

  const AlunoTodayFocusCard({
    super.key,
    required this.action,
    required this.hoje,
    required this.isDark,
    required this.onAction,
    this.onOpen,
    this.insight,
    this.horario,
    this.prontidaoBaixa = false,
    this.semana = const [],
    this.onSemana,
    this.seloFicha,
    this.seloFichaTom = FxPillTone.accent,
    this.onVerTreinos,
    this.fundoMarca,
    this.assinatura,
  });

  /// Nome curto do próximo dia de treino na semana ("Qua"), se houver.
  static String? proximoDiaNome(S s, List<FxWeekDay> semana) {
    final nomes = FxWeekStrip.nomes(s);
    for (final d in semana) {
      if (d.proximo && d.dia >= 1 && d.dia <= nomes.length) {
        return nomes[d.dia - 1];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = alunoTodayTexto(
      s,
      action,
      hoje: hoje,
      prontidaoBaixa: prontidaoBaixa,
      proximoDia: proximoDiaNome(s, semana),
    );
    final chrome = ShellChrome.forBrightness(context, isDark);
    final mute = chrome.mute;
    final nomeAssinatura = assinatura?.trim() ?? '';
    final eyebrow =
        action.mode == AlunoTodayMode.workoutReady &&
                !action.comeback &&
                !action.continuar &&
                nomeAssinatura.isNotEmpty
            ? s.alunoHojeTreinoComPersonal(nomeAssinatura)
            : texto.eyebrow;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap: com fonte grande o selo desce para a linha de baixo.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: TokensStrip.s1,
                children: [
                  Text(
                    eyebrow,
                    style: FocuxHubTypography.eyebrow(context, color: mute),
                  ),
                  if (seloFicha case final selo?)
                    FxStatusPill(label: selo, tone: seloFichaTom),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                texto.titulo,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                texto.descricao,
                style: FocuxHubTypography.bodyMuted(color: mute),
              ),
            ],
          ),
        ),
        if (texto.prazo case final prazo?) ...[
          const SizedBox(height: TokensStrip.s1),
          Text(prazo, style: FocuxHubTypography.bodyMuted(color: mute)),
        ],
        if (horario case final h?) ...[
          const SizedBox(height: TokensStrip.s1),
          Text(
            alunoHorarioFocoTexto(s, h, hoje: hoje),
            style: FocuxHubTypography.bodyMuted(
              color: chrome.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (insight case final insight?) ...[
          const SizedBox(height: TokensStrip.s3),
          AlunoHomeInsightLine(insight: insight, onPrimary: mute),
        ],
        if (semana.isNotEmpty) ...[
          const SizedBox(height: TokensStrip.s3),
          Semantics(
            button: onSemana != null,
            label:
                '${s.alunoSemanaFaixaTitulo}. ${FxWeekStrip.semantica(s, semana)}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onSemana,
              borderRadius: BorderRadius.circular(TokensStrip.rMd),
              child: FxWeekStrip(dias: semana),
            ),
          ),
        ],
        const SizedBox(height: TokensStrip.s3),
        ..._acoes(context, s, texto),
      ],
    );

    // Com marca, o gradiente vai por dentro do card (o fundo dele é opaco):
    // camada atrás do conteúdo, mesmo raio do card.
    final comMarca = fundoMarca != null;
    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      padding:
          comMarca ? EdgeInsets.zero : const EdgeInsets.all(TokensStrip.s4),
      child:
          comMarca
              ? Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: fundoMarca,
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rCard,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(TokensStrip.s4),
                    child: conteudo,
                  ),
                ],
              )
              : conteudo,
    );
  }

  /// Uma ação principal por card; a secundária é link com seta (nunca texto solto).
  List<Widget> _acoes(BuildContext context, S s, AlunoTodayTexto texto) {
    switch (action.mode) {
      case AlunoTodayMode.descansoHoje:
        return [
          FxTonalButton(
            label: s.alunoHojeVerTreino,
            icon: Icons.fitness_center_rounded,
            expanded: true,
            onPressed: onVerTreinos ?? onAction,
          ),
          const SizedBox(height: TokensStrip.s1),
          Align(
            alignment: Alignment.centerLeft,
            child: FxActionLink(label: texto.cta, onTap: onAction),
          ),
        ];
      case AlunoTodayMode.workoutDone:
        final temProximo = action.proximoTreinoNome?.trim().isNotEmpty ?? false;
        if (temProximo && onOpen != null) {
          return [
            FxTonalButton(
              label: texto.cta,
              icon: Icons.add_rounded,
              expanded: true,
              onPressed: onAction,
            ),
            const SizedBox(height: TokensStrip.s1),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionLink(label: s.alunoHojeFeitoCta, onTap: onOpen),
            ),
          ];
        }
        return [
          FxTonalButton(label: texto.cta, expanded: true, onPressed: onAction),
        ];
      default:
        if (texto.ctaPrimario) {
          return [FxLiquidPrimaryButton(label: texto.cta, onPressed: onAction)];
        }
        return [
          FxTonalButton(label: texto.cta, expanded: true, onPressed: onAction),
        ];
    }
  }
}

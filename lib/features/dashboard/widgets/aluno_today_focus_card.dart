import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/brand_style.dart';
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

  /// Estilo da marca e cor primária do personal. No Cinematográfico o card é
  /// sólido na cor da marca; no Minimalista é só contorno; sem marca (ou
  /// Clássico) fica o card branco de sempre.
  final BrandStyle estilo;
  final Color? primaria;

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
    this.estilo = BrandStyle.classico,
    this.primaria,
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
    final solido =
        estilo.cardSolido && primaria != null
            ? BrandPalette.cardDeMarca(primaria!, dark: isDark)
            : null;
    final sobre = solido?.sobre;
    final chrome = ShellChrome.forBrightness(context, sobre != null || isDark);
    final mute = sobre?.withValues(alpha: 0.80) ?? chrome.mute;
    final tinta = sobre ?? chrome.ink;
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
                style: FocuxHubTypography.pageTitle(context, color: tinta),
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
              color: tinta,
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
              child: FxWeekStrip(dias: semana, sobre: sobre),
            ),
          ),
        ],
        const SizedBox(height: TokensStrip.s3),
        ..._acoes(context, s, texto, solido),
      ],
    );

    if (solido != null) {
      // Cinematográfico: card sólido na cor da marca, com tudo por dentro em
      // tema escuro (texto, selo e faixa da semana claros sobre o fundo).
      final base = Theme.of(context);
      final escuro = base.copyWith(
        brightness: Brightness.dark,
        colorScheme: base.colorScheme.copyWith(
          brightness: Brightness.dark,
          primary: solido.sobre,
        ),
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: solido.degrade,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          boxShadow: [
            BoxShadow(
              color: solido.fundo.withValues(alpha: isDark ? 0.30 : 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Theme(data: escuro, child: conteudo),
        ),
      );
    }
    if (estilo == BrandStyle.minimalista) {
      // Minimalista: sem preenchimento, só contorno fino.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: chrome.lineStrong),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: conteudo,
        ),
      );
    }
    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      padding: const EdgeInsets.all(TokensStrip.s4),
      child: conteudo,
    );
  }

  /// Uma ação principal por card; a secundária é link com seta (nunca texto solto).
  List<Widget> _acoes(
    BuildContext context,
    S s,
    AlunoTodayTexto texto,
    CardDeMarca? solido,
  ) {
    // Sobre o card sólido: botão tonal translúcido; o principal é branco com
    // texto na cor do card.
    final fundoTonal = solido?.sobre.withValues(alpha: 0.18);
    final textoTonal = solido?.sobre;
    switch (action.mode) {
      case AlunoTodayMode.descansoHoje:
        return [
          FxTonalButton(
            label: s.alunoHojeVerTreino,
            icon: Icons.fitness_center_rounded,
            expanded: true,
            fundo: fundoTonal,
            texto: textoTonal,
            onPressed: onVerTreinos ?? onAction,
          ),
          const SizedBox(height: TokensStrip.s1),
          Align(
            alignment: Alignment.centerLeft,
            child: FxActionLink(
              label: texto.cta,
              onTap: onAction,
              fundo: fundoTonal,
              texto: textoTonal,
            ),
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
              fundo: fundoTonal,
              texto: textoTonal,
              onPressed: onAction,
            ),
            const SizedBox(height: TokensStrip.s1),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionLink(
                label: s.alunoHojeFeitoCta,
                onTap: onOpen,
                fundo: fundoTonal,
                texto: textoTonal,
              ),
            ),
          ];
        }
        return [
          FxTonalButton(
            label: texto.cta,
            expanded: true,
            fundo: fundoTonal,
            texto: textoTonal,
            onPressed: onAction,
          ),
        ];
      default:
        if (texto.ctaPrimario) {
          if (solido != null) {
            return [
              FxTonalButton(
                label: texto.cta,
                expanded: true,
                fundo: solido.sobre,
                texto: solido.fundo,
                onPressed: onAction,
              ),
            ];
          }
          return [FxLiquidPrimaryButton(label: texto.cta, onPressed: onAction)];
        }
        return [
          FxTonalButton(
            label: texto.cta,
            expanded: true,
            fundo: fundoTonal,
            texto: textoTonal,
            onPressed: onAction,
          ),
        ];
    }
  }
}

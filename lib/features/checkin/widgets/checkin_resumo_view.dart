import '../../../core/theme/focux_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_confetti_burst.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_resumo.dart';
import '../utils/historico_detalhe_texts.dart';
import '../utils/treinos_hub_texts.dart';
import 'checkin_execucao_sheets.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_week_strip.dart';
import '../../../core/widgets/fx_action_link.dart';

enum CheckinResumoAcao { concluir, detalhes }

/// Verdadeiro enquanto a tela de fim de treino está aberta. Pedidos que
/// interrompem (nota do NPS) esperam ela fechar: o resumo vai por cima do
/// roteador, então a rota da Home continua "na frente" por baixo dele.
final ValueNotifier<bool> checkinResumoAberto = ValueNotifier(false);

/// Tela cheia do fim do treino. Voltar do sistema equivale a "Concluir".
Future<CheckinResumoAcao> showCheckinResumo(
  BuildContext context, {
  required CheckinResumo resumo,
  String? titulo,
  String? mensagem,
  CheckinResumoSemana? semana,
}) async {
  HapticFeedback.mediumImpact();
  checkinResumoAberto.value = true;
  final acao = await Navigator.of(context, rootNavigator: true)
      .push(
    PageRouteBuilder<CheckinResumoAcao>(
      fullscreenDialog: true,
      transitionDuration: fxMotionDuration(
        context,
        normal: const Duration(milliseconds: 280),
      ),
      pageBuilder:
          (_, __, ___) => CheckinResumoView(
            resumo: resumo,
            semana: semana,
            titulo: titulo,
            mensagem: mensagem,
          ),
      transitionsBuilder:
          (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    ),
  )
      .whenComplete(() => checkinResumoAberto.value = false);
  return acao ?? CheckinResumoAcao.concluir;
}

class CheckinResumoView extends StatelessWidget {
  const CheckinResumoView({
    super.key,
    required this.resumo,
    this.titulo,
    this.mensagem,
    this.semana,
  });

  final CheckinResumo resumo;

  /// Semana com hoje feito, meta e próximo da fila (só no fim do treino).
  final CheckinResumoSemana? semana;

  /// Texto no lugar de "Treino concluído" e frase abaixo ("Já fiz").
  final String? titulo;
  final String? mensagem;

  bool get _celebra =>
      !resumo.parcial &&
      (resumo.recordes.isNotEmpty ||
          resumo.comparacao?.tipo == CheckinResumoComparacaoTipo.mais);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final reduce = reduceMotionOf(context);
    final comparacao = checkinResumoComparacaoTexto(s, resumo.comparacao);
    final destaque = resumo.destaque;

    Widget check = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
      child: Icon(FxIcons.check, color: FocuxContrast.readableOn(primary), size: 48),
    );
    if (!reduce) {
      check = check
          .animate()
          .scale(
            begin: const Offset(0.6, 0.6),
            duration: 420.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 200.ms);
    }

    return Scaffold(
      body: Stack(
        children: [
          if (_celebra && !reduce)
            Positioned.fill(child: FxConfettiBurst(color: primary)),
          SafeArea(
            child: FxContentWidthLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s6,
                        TokensStrip.s4,
                        TokensStrip.s4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: ExcludeSemantics(child: check)),
                          const SizedBox(height: TokensStrip.s4),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              resumo.treinoNome,
                              textAlign: TextAlign.center,
                              style: FocuxTypography.headline(
                                color: chrome.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            titulo ??
                                (resumo.parcial
                                    ? s.checkinResumoTituloParcial
                                    : s.checkinResumoTitulo),
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          ),
                          if (mensagem case final frase?) ...[
                            const SizedBox(height: TokensStrip.s4),
                            Text(
                              frase,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.body(color: chrome.ink),
                            ),
                          ],
                          if (resumo.temNumeros) ...[
                            const SizedBox(height: TokensStrip.s6),
                            _Numeros(resumo: resumo),
                          ],
                          if (resumo.parcial) ...[
                            const SizedBox(height: TokensStrip.s4),
                            Text(
                              s.checkinResumoParcialDica(
                                resumo.seriesFeitas,
                                resumo.seriesPlanejadas,
                              ),
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                          ] else if (comparacao != null) ...[
                            const SizedBox(height: TokensStrip.s4),
                            Text(
                              comparacao,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.body(
                                color: chrome.mute,
                              ),
                            ),
                          ],
                          if (resumo.seriesSemCarga > 0) ...[
                            const SizedBox(height: TokensStrip.s4),
                            _Linha(
                              icone: FxIcons.treino,
                              cor: chrome.mute,
                              texto:
                                  '${s.checkinResumoSemCarga(resumo.seriesSemCarga)}. '
                                  '${s.checkinResumoSemCargaDica}',
                            ),
                            if (mensagem == null)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: FxActionLink(
                                  label: s.checkinResumoAnotarCargas,
                                  onTap:
                                      () => Navigator.of(
                                        context,
                                      ).pop(CheckinResumoAcao.detalhes),
                                ),
                              ),
                          ],
                          if (semana case final sem?) ...[
                            const SizedBox(height: TokensStrip.s6),
                            _SuaSemana(semana: sem),
                          ],
                          if (resumo.recordes.isNotEmpty) ...[
                            const SizedBox(height: TokensStrip.s6),
                            Text(
                              s.checkinResumoRecordes,
                              style: FocuxHubTypography.sectionTitle(
                                context,
                                color: chrome.ink,
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s2),
                            for (final e in resumo.recordes.take(5))
                              _Linha(
                                icone: FxIcons.trofeu,
                                cor: EagleTokens.good,
                                texto: checkinEvolucaoLinha(s, e),
                              ),
                          ] else if (destaque != null) ...[
                            const SizedBox(height: TokensStrip.s4),
                            _Linha(
                              icone: FxIcons.subindo,
                              cor: primary,
                              texto: s.historicoDestaqueCarga(
                                destaque.exercicio,
                                historicoDeltaKg(s, destaque.deltaKg),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      TokensStrip.s4,
                      TokensStrip.s4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxLiquidPrimaryButton(
                          label: s.checkinResumoConcluir,
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(CheckinResumoAcao.concluir),
                        ),
                        if (mensagem == null) ...[
                          const SizedBox(height: TokensStrip.s2),
                          FxTonalButton(
                            label: s.checkinResumoDetalhes,
                            expanded: true,
                            onPressed:
                                () => Navigator.of(
                                  context,
                                ).pop(CheckinResumoAcao.detalhes),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? checkinResumoComparacaoTexto(S s, CheckinResumoComparacao? c) =>
    switch (c?.tipo) {
      CheckinResumoComparacaoTipo.mais => s.checkinResumoMais(c!.percentual),
      CheckinResumoComparacaoTipo.menos => s.checkinResumoMenos(c!.percentual),
      CheckinResumoComparacaoTipo.igual => s.checkinResumoIgual,
      CheckinResumoComparacaoTipo.primeira => s.checkinResumoPrimeira,
      null => null,
    };

class _Numeros extends StatelessWidget {
  const _Numeros({required this.resumo});

  final CheckinResumo resumo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final duracao = resumo.duracao;
    final volume = resumo.volumeKg;
    final itens = [
      if (duracao != null)
        (s.checkinResumoDuracao, treinosDuracaoTexto(s, duracao)),
      if (resumo.seriesFeitas > 0)
        (
          s.checkinResumoSeries,
          historicoNDeMTexto(s, resumo.seriesFeitas, resumo.seriesPlanejadas),
        ),
      // Com a maioria sem carga, o volume engana: mostra quantas tiveram carga.
      if (resumo.seriesSemCarga * 2 > resumo.seriesFeitas &&
          resumo.seriesFeitas > 0)
        (
          s.checkinResumoComCarga,
          historicoNDeMTexto(
            s,
            (resumo.seriesFeitas - resumo.seriesSemCarga).clamp(0, 999).toInt(),
            resumo.seriesFeitas,
          ),
        )
      else if (volume != null)
        (s.checkinResumoVolume, historicoKgTexto(s, volume)),
    ];
    return Row(
      children: [
        for (final (label, valor) in itens)
          Expanded(child: _Numero(label: label, valor: valor)),
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return MergeSemantics(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              style: FocuxHubTypography.metric(color: chrome.ink, fontSize: TokensStrip.fontTitulo),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.cor, required this.texto});

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Text(
              texto,
              style: FocuxHubTypography.body(
                color: ShellChrome.of(context).ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa da semana com hoje feito, "3 de 5 treinos" e o próximo da fila.
class _SuaSemana extends StatelessWidget {
  const _SuaSemana({required this.semana});

  final CheckinResumoSemana semana;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final meta = semana.meta;
    final contagem =
        meta != null && meta > 0
            ? s.checkinResumoSemanaDeMeta(semana.feitos, meta)
            : s.checkinResumoSemanaFeitos(semana.feitos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.checkinResumoSuaSemana,
          style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxWeekStrip(dias: semana.dias),
        const SizedBox(height: TokensStrip.s3),
        Text(
          [
            contagem,
            if (semana.proximo case final p?) s.checkinResumoProximo(p),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ],
    );
  }
}

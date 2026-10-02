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
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_resumo.dart';
import '../utils/historico_detalhe_texts.dart';
import '../utils/treinos_hub_texts.dart';
import 'checkin_execucao_sheets.dart';

enum CheckinResumoAcao { concluir, detalhes }

/// Tela cheia do fim do treino. Voltar do sistema equivale a "Concluir".
Future<CheckinResumoAcao> showCheckinResumo(
  BuildContext context, {
  required CheckinResumo resumo,
}) async {
  HapticFeedback.mediumImpact();
  final acao = await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<CheckinResumoAcao>(
      fullscreenDialog: true,
      transitionDuration: fxMotionDuration(
        context,
        normal: const Duration(milliseconds: 280),
      ),
      pageBuilder: (_, __, ___) => CheckinResumoView(resumo: resumo),
      transitionsBuilder:
          (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    ),
  );
  return acao ?? CheckinResumoAcao.concluir;
}

class CheckinResumoView extends StatelessWidget {
  const CheckinResumoView({super.key, required this.resumo});

  final CheckinResumo resumo;

  bool get _celebra =>
      resumo.recordes.isNotEmpty ||
      resumo.comparacao?.tipo == CheckinResumoComparacaoTipo.mais;

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
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
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
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            s.checkinResumoTitulo,
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          ),
                          if (resumo.temNumeros) ...[
                            const SizedBox(height: TokensStrip.s6),
                            _Numeros(resumo: resumo),
                          ],
                          if (comparacao != null) ...[
                            const SizedBox(height: TokensStrip.s4),
                            Text(
                              comparacao,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.body(
                                color: chrome.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
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
                                icone: Icons.emoji_events_rounded,
                                cor: EagleTokens.good,
                                texto: checkinEvolucaoLinha(s, e),
                              ),
                          ] else if (destaque != null) ...[
                            const SizedBox(height: TokensStrip.s4),
                            _Linha(
                              icone: Icons.trending_up_rounded,
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
                        FilledButton(
                          autofocus: true,
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(CheckinResumoAcao.concluir),
                          child: Text(s.checkinResumoConcluir),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        TextButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(CheckinResumoAcao.detalhes),
                          child: Text(s.checkinResumoDetalhes),
                        ),
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
      if (volume != null) (s.checkinResumoVolume, historicoKgTexto(s, volume)),
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
              style: FocuxHubTypography.metric(color: chrome.ink, fontSize: 22),
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

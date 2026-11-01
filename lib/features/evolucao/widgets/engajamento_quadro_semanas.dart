import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../utils/engajamento_display.dart';

const _tamanhoDoDia = 32.0;

/// Cinco semanas de segunda a domingo. Ícone e cor juntos dizem o estado.
class EngajamentoQuadroSemanas extends StatelessWidget {
  const EngajamentoQuadroSemanas({
    super.key,
    required this.semanas,
    required this.resumo,
  });

  final List<EngajamentoSemana> semanas;
  final String resumo;

  static (IconData?, String) _simbolo(EngajamentoDiaEstado estado) =>
      switch (estado) {
        EngajamentoDiaEstado.treinou => (Icons.check_rounded, ptS.engajamentoTreinou),
        EngajamentoDiaEstado.parcial => (Icons.contrast_rounded, ptS.historicoParcial),
        EngajamentoDiaEstado.cancelou => (Icons.remove_rounded, ptS.engajamentoCancelou),
        EngajamentoDiaEstado.faltou => (Icons.close_rounded, ptS.engajamentoFaltou),
        EngajamentoDiaEstado.descanso => (null, ptS.engajamentoDescanso),
        EngajamentoDiaEstado.semRegistro => (null, ptS.engajamentoSemRegistro),
        EngajamentoDiaEstado.futuro => (null, ptS.engajamentoAindaNaoChegou),
      };

  void _abrirDia(BuildContext context, EngajamentoDia dia) {
    final chrome = ShellChrome.of(context);
    showFxHomeSheet<void>(
      context,
      builder:
          (_) => FxSheetFrame(
            title: engajamentoDiaCompleto(dia.dia),
            child: Text(
              _simbolo(dia.estado).$2,
              style: FocuxHubTypography.body(color: chrome.ink),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final legendas = {
      for (final s in semanas)
        for (final d in s.dias)
          if (d.estado != EngajamentoDiaEstado.futuro) d.estado,
    };
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ptS.engajamentoUltimas5Semanas,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          Text(resumo, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          const SizedBox(height: TokensStrip.s3),
          ExcludeSemantics(
            child: Row(
              children: [
                const SizedBox(width: 44),
                for (final letra in const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'])
                  Expanded(
                    child: Center(
                      child: Text(
                        letra,
                        style: FocuxHubTypography.chip(chrome.mute),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          for (final semana in semanas)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s1),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      engajamentoDataCurta(semana.inicio),
                      style: FocuxHubTypography.chip(chrome.mute),
                    ),
                  ),
                  for (final dia in semana.dias)
                    Expanded(
                      child: Center(
                        child: _Dia(
                          dia: dia,
                          simbolo: _simbolo(dia.estado),
                          onTap:
                              dia.estado == EngajamentoDiaEstado.futuro
                                  ? null
                                  : () => _abrirDia(context, dia),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: TokensStrip.s2),
          ExcludeSemantics(
            child: Wrap(
              spacing: TokensStrip.s3,
              runSpacing: TokensStrip.s1,
              children: [
                for (final estado in EngajamentoDiaEstado.values)
                  if (legendas.contains(estado))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.6,
                          child: _Dia(
                            dia: null,
                            estado: estado,
                            simbolo: _simbolo(estado),
                          ),
                        ),
                        Text(
                          _simbolo(estado).$2,
                          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.dia,
    required this.simbolo,
    this.estado,
    this.onTap,
  });

  final EngajamentoDia? dia;
  final EngajamentoDiaEstado? estado;
  final (IconData?, String) simbolo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final aviso = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    final atual = dia?.estado ?? estado!;
    final (fundo, tinta) = switch (atual) {
      EngajamentoDiaEstado.treinou => (primary, Theme.of(context).colorScheme.onPrimary),
      EngajamentoDiaEstado.parcial => (primary.withValues(alpha: 0.28), primary),
      EngajamentoDiaEstado.cancelou => (aviso.withValues(alpha: 0.18), aviso),
      EngajamentoDiaEstado.faltou => (chrome.line, chrome.mute),
      EngajamentoDiaEstado.descanso => (Colors.transparent, chrome.mute),
      EngajamentoDiaEstado.semRegistro => (Colors.transparent, chrome.mute),
      EngajamentoDiaEstado.futuro => (Colors.transparent, chrome.mute),
    };
    final caixa = Container(
      width: _tamanhoDoDia,
      height: _tamanhoDoDia,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border:
            dia?.hoje == true
                ? Border.all(color: chrome.ink, width: 2)
                : atual == EngajamentoDiaEstado.descanso ||
                    atual == EngajamentoDiaEstado.semRegistro
                ? Border.all(color: chrome.line)
                : null,
      ),
      child:
          simbolo.$1 == null ? null : Icon(simbolo.$1, size: 18, color: tinta),
    );
    final d = dia;
    if (d == null) return caixa;
    return Semantics(
      button: onTap != null,
      label: '${engajamentoDiaCompleto(d.dia)}, ${simbolo.$2}',
      excludeSemantics: true,
      child: GestureDetector(onTap: onTap, child: caixa),
    );
  }
}

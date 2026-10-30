import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/ficha_vigencia.dart';

/// A ficha tem algo a dizer ao aluno: prazo ou troca recente.
bool temAvisoDaFicha(RotinaFila rotina, DateTime agora) =>
    rotina.temTreino &&
    (rotina.vigencia.temPrazo ||
        fichaAtualizadaRecentemente(rotina.atualizadaEm, agora));

/// Linha da ficha para o aluno: "Ficha até 30/11" e, se trocada há pouco,
/// "Ficha atualizada". A validade orienta, nunca bloqueia: vencida vira um
/// aviso suave.
class FichaVigenciaAluno extends StatelessWidget {
  const FichaVigenciaAluno({
    super.key,
    required this.rotina,
    required this.hoje,
    this.prazoNoTitulo = false,
  });

  final RotinaFila rotina;
  final DateTime hoje;

  /// A data já está no título da seção: aqui só o aviso de vencimento.
  final bool prazoNoTitulo;

  @override
  Widget build(BuildContext context) {
    if (!temAvisoDaFicha(rotina, hoje)) return const SizedBox.shrink();
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final vigencia = rotina.vigencia;
    final dias = vigencia.diasRestantes(hoje) ?? 0;
    final aviso = switch (vigencia.estado(hoje)) {
      EstadoVigencia.venceEmBreve ||
      EstadoVigencia.venceHoje ||
      EstadoVigencia.vencida => true,
      _ => false,
    };
    final prazo = switch (vigencia.estado(hoje)) {
      EstadoVigencia.semPrazo => null,
      EstadoVigencia.emDia =>
        prazoNoTitulo ? null : s.alunoFichaAte(dataCurta(vigencia.fim!)),
      EstadoVigencia.venceEmBreve => s.alunoFichaVenceEmDias(dias),
      EstadoVigencia.venceHoje => s.alunoFichaVenceHoje,
      EstadoVigencia.vencida => s.alunoFichaVenceu,
    };
    final atualizada = fichaAtualizadaRecentemente(rotina.atualizadaEm, hoje);
    if (prazo == null && !atualizada) return const SizedBox.shrink();
    final cor = aviso
        ? (chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn)
        : chrome.mute;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          aviso ? Icons.event_busy_outlined : Icons.event_note_outlined,
          size: 18,
          color: cor,
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: Wrap(
            spacing: TokensStrip.s3,
            runSpacing: TokensStrip.s1,
            children: [
              if (prazo != null)
                Text(
                  prazo,
                  style: FocuxHubTypography.bodyMuted(
                    color: aviso ? cor : chrome.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (atualizada)
                Text(
                  s.alunoFichaAtualizada,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

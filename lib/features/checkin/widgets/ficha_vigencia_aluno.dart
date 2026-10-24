import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/ficha_vigencia.dart';

/// A ficha tem algo a dizer ao aluno: prazo ou troca recente.
bool temAvisoDaFicha(RotinaFila rotina, DateTime agora) =>
    rotina.temTreino &&
    (rotina.vigencia.temPrazo ||
        fichaAtualizadaRecentemente(rotina.atualizadaEm, agora));

/// Chips discretos para o aluno: "Ficha até 30/11" e "Ficha atualizada".
/// A validade orienta, nunca bloqueia: vencida vira um aviso suave.
class FichaVigenciaAluno extends StatelessWidget {
  const FichaVigenciaAluno({super.key, required this.rotina, required this.hoje});

  final RotinaFila rotina;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    if (!temAvisoDaFicha(rotina, hoje)) return const SizedBox.shrink();
    final s = S.of(context);
    final vigencia = rotina.vigencia;
    final dias = vigencia.diasRestantes(hoje) ?? 0;
    final prazo = switch (vigencia.estado(hoje)) {
      EstadoVigencia.semPrazo => null,
      EstadoVigencia.emDia => (s.alunoFichaAte(dataCurta(vigencia.fim!)), FxPillTone.neutral),
      EstadoVigencia.venceEmBreve => (s.alunoFichaVenceEmDias(dias), FxPillTone.warning),
      EstadoVigencia.venceHoje => (s.alunoFichaVenceHoje, FxPillTone.warning),
      EstadoVigencia.vencida => (s.alunoFichaVenceu, FxPillTone.warning),
    };
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        if (prazo != null) FxStatusPill(label: prazo.$1, tone: prazo.$2),
        if (fichaAtualizadaRecentemente(rotina.atualizadaEm, hoje))
          FxStatusPill(
            label: s.alunoFichaAtualizada,
            tone: FxPillTone.accent,
            icon: Icons.update_rounded,
          ),
      ],
    );
  }
}

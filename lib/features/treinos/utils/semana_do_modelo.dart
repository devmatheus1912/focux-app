import '../models/ficha_modelo.dart';
import 'semana_da_fila.dart';

/// A semana de um modelo no mesmo formato da ficha: sete dias, sessões em cada
/// um, descanso nos dias de aviso e "segue a sequência" nos outros.
/// Item sem dia válido fica de fora.
List<DiaDaSemana> semanaDoModelo(FichaModelo modelo) {
  final porDia = <int, List<SessaoDaSemana>>{};
  for (final item in modelo.sessoes) {
    final dia = item.diaSemana;
    if (dia == null || dia < 1 || dia > 7) continue;
    porDia.putIfAbsent(dia, () => []).add(
      SessaoDaSemana(
        treinoId: item.treinoId,
        nome: item.nome,
        exerciciosCount: item.exerciciosCount,
      ),
    );
  }
  final avisos = modelo.avisoDias.toSet();
  return [
    for (var dia = 1; dia <= 7; dia++)
      if ((porDia[dia] ?? const []).isNotEmpty)
        DiaDaSemana(dia: dia, sessoes: porDia[dia]!)
      else if (avisos.contains(dia) || porDia.isEmpty)
        DiaDaSemana(dia: dia, descanso: true)
      else
        // Fora do aviso num modelo com sessões: segue a sequência (rodízio).
        DiaDaSemana(dia: dia, segueSequencia: true),
  ];
}

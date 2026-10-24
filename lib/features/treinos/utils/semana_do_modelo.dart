import '../models/ficha_modelo.dart';
import 'semana_da_fila.dart';

/// A semana de um modelo no mesmo formato da ficha: sete dias, sessões em cada
/// um e descanso nos outros. Item sem dia válido fica de fora.
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
  return [
    for (var dia = 1; dia <= 7; dia++)
      DiaDaSemana(
        dia: dia,
        sessoes: porDia[dia] ?? const [],
        descanso: (porDia[dia] ?? const []).isEmpty,
      ),
  ];
}

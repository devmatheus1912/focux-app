import '../../treinos/models/metodo_exercicio.dart';
import '../models/checkin_execucao_models.dart';

/// Depois de uma série: para qual exercício ir e se descansa agora.
/// No combinado (bi-set, tri-set) a volta passa por todos sem descanso; o
/// descanso vem depois do último, e a próxima volta recomeça no primeiro.
({int? focoId, bool descansar}) passoDoCombinado(
  List<ExecucaoExercicio> exercicios,
  ExecucaoExercicio feito,
) {
  final grupo = feito.metodo.grupo;
  if (grupo == null) return (focoId: null, descansar: true);
  final membros = [for (final e in exercicios) if (e.metodo.grupo == grupo) e];
  bool falta(ExecucaoExercicio e) => e.seriesFeitas < (e.series ?? 0);
  final i = membros.indexWhere((e) => e.treinoExercicioId == feito.treinoExercicioId);
  for (var k = i + 1; k < membros.length; k++) {
    if (falta(membros[k])) return (focoId: membros[k].treinoExercicioId, descansar: false);
  }
  final proximaVolta = membros.where(falta).firstOrNull;
  return (focoId: proximaVolta?.treinoExercicioId, descansar: true);
}

/// Carga da queda [n] (1, 2, 3) no drop-set, arredondada ao [passo] (0,5 kg).
double cargaDaQueda(double inicial, int n, int reducaoPct, {double passo = 0.5}) {
  var carga = inicial;
  for (var i = 0; i < n; i++) {
    carga = carga * (1 - reducaoPct / 100);
  }
  return (carga / passo).round() * passo;
}

/// Os passos que vêm logo depois da série, sem descanso cheio entre eles.
/// Drop-set: uma queda por passo, com a carga já reduzida.
/// Rest-pause: uma pausa curta e uma mini-série por passo.
List<({String titulo, String apoio, int? pausaS})> passosDoMetodo(
  MetodoExercicio metodo, {
  double? cargaDaSerie,
}) => switch (metodo.tecnica) {
  Tecnica.dropset => [
    for (var n = 1; n <= (metodo.quedas ?? 2); n++)
      (
        titulo: cargaDaSerie == null || cargaDaSerie <= 0
            ? 'Drop $n · −${(metodo.reducaoPct ?? 20) * n}% da carga'
            : 'Drop $n · ${_kg(cargaDaQueda(cargaDaSerie, n, metodo.reducaoPct ?? 20))}',
        apoio: 'Sem descanso: tire o peso e vá até a falha.',
        pausaS: null,
      ),
  ],
  Tecnica.restpause => [
    for (var n = 1; n <= (metodo.miniSeries ?? 2); n++)
      (
        titulo: 'Mini-série $n de ${metodo.miniSeries ?? 2}',
        apoio: 'Mesma carga, o máximo de repetições.',
        pausaS: metodo.pausaS ?? 15,
      ),
  ],
  _ => const [],
};

String _kg(double v) => v == v.roundToDouble() ? '${v.toInt()} kg' : '${v.toStringAsFixed(1).replaceAll('.', ',')} kg';

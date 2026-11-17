import 'prescricao_atalhos.dart';
import 'prescricao_serie.dart';

/// Papel de uma série. Só Válida e Back-off contam em volume e parcial.
abstract final class PapelDaSerie {
  static const aquecimento = 'AQUECIMENTO';
  static const ajuste = 'AJUSTE';
  static const valida = 'VALIDA';
  static const backoff = 'BACKOFF';

  /// Ordem sugerida na execução.
  static const ordem = [aquecimento, ajuste, valida, backoff];

  static bool conta(String papel) => papel == valida || papel == backoff;

  static String rotulo(String papel) => switch (papel) {
    aquecimento => 'Aquecimento',
    ajuste => 'Ajuste',
    backoff => 'Back-off',
    _ => 'Válida',
  };

  /// Forma curta para o resumo da linha ("2 aquec.", "3 ajuste").
  static String curto(String papel) => switch (papel) {
    aquecimento => 'aquec.',
    ajuste => 'ajuste',
    backoff => 'back-off',
    _ => 'válidas',
  };
}

/// Séries seguidas com o mesmo papel, reps, carga e descanso.
class GrupoDeSeries {
  const GrupoDeSeries({
    required this.papel,
    required this.series,
    required this.repeticoes,
    this.cargaKg,
    this.descansoSegundos,
  });

  final String papel;
  final int series;
  final String repeticoes;
  final double? cargaKg;
  final int? descansoSegundos;

  GrupoDeSeries copyWith({
    String? papel,
    int? series,
    String? repeticoes,
    double? cargaKg,
    bool limparCarga = false,
    int? descansoSegundos,
  }) => GrupoDeSeries(
    papel: papel ?? this.papel,
    series: series ?? this.series,
    repeticoes: repeticoes ?? this.repeticoes,
    cargaKg: limparCarga ? null : (cargaKg ?? this.cargaKg),
    descansoSegundos: descansoSegundos ?? this.descansoSegundos,
  );

  List<SeriePrescrita> linhas() => [
    for (var i = 0; i < series; i++)
      SeriePrescrita(
        numero: i + 1,
        repeticoes: repeticoes,
        cargaKg: cargaKg,
        papel: papel,
        descansoSegundos: descansoSegundos,
      ),
  ];
}

/// Agrupa linhas seguidas iguais (papel, reps, carga e descanso).
List<GrupoDeSeries> agruparSeries(List<SeriePrescrita> linhas) {
  final ordenadas = [...linhas]..sort((a, b) => a.numero.compareTo(b.numero));
  final grupos = <GrupoDeSeries>[];
  for (final l in ordenadas) {
    final ultimo = grupos.isEmpty ? null : grupos.last;
    if (ultimo != null &&
        ultimo.papel == l.papel &&
        ultimo.repeticoes == l.repeticoes &&
        ultimo.cargaKg == l.cargaKg &&
        ultimo.descansoSegundos == l.descansoSegundos) {
      grupos[grupos.length - 1] = ultimo.copyWith(series: ultimo.series + 1);
    } else {
      grupos.add(GrupoDeSeries(
        papel: l.papel,
        series: 1,
        repeticoes: l.repeticoes,
        cargaKg: l.cargaKg,
        descansoSegundos: l.descansoSegundos,
      ));
    }
  }
  return grupos;
}

/// Linhas numeradas de novo, na ordem dos grupos.
List<SeriePrescrita> desagruparSeries(List<GrupoDeSeries> grupos) {
  final linhas = <SeriePrescrita>[];
  for (final g in grupos) {
    for (final l in g.linhas()) {
      linhas.add(l.comNumero(linhas.length + 1));
    }
  }
  return linhas;
}

/// Grupos fora das válidas: os que vêm antes da primeira válida e os de depois
/// da última. As válidas ficam nos controles da folha.
({List<GrupoDeSeries> antes, List<GrupoDeSeries> depois}) gruposExtras(
  List<SeriePrescrita> linhas,
) {
  final grupos = agruparSeries(linhas);
  final primeira = grupos.indexWhere((g) => g.papel == PapelDaSerie.valida);
  if (primeira < 0) {
    return (
      antes: [for (final g in grupos) if (g.papel != PapelDaSerie.backoff) g],
      depois: [for (final g in grupos) if (g.papel == PapelDaSerie.backoff) g],
    );
  }
  final ultima = grupos.lastIndexWhere((g) => g.papel == PapelDaSerie.valida);
  return (
    antes: [for (final g in grupos.take(primeira)) g],
    depois: [
      for (final g in grupos.skip(ultima + 1))
        if (g.papel != PapelDaSerie.valida) g,
    ],
  );
}

/// Grupo novo com valores sugeridos. Back-off: 2 séries (ou menos, se as
/// válidas forem menos), mesmas reps, 80% da carga arredondada para 0,5 kg.
/// Repetições de um toque por papel do grupo; o resto vai pelo "Outro".
/// Back-off usa os atalhos das válidas do bloco.
List<String> atalhosDoGrupo(String papel, String bloco) => switch (papel) {
  PapelDaSerie.aquecimento => const ['15', '12', '10', '8'],
  PapelDaSerie.ajuste => const ['5', '3', '2', '1'],
  _ => atalhosRepeticoes(bloco),
};

GrupoDeSeries grupoSugerido(
  String papel, {
  required int seriesValidas,
  required String repsValidas,
  double? cargaValidas,
  int? descansoValidas,
}) => switch (papel) {
  PapelDaSerie.aquecimento => const GrupoDeSeries(
    papel: PapelDaSerie.aquecimento,
    series: 2,
    repeticoes: '12',
    descansoSegundos: 60,
  ),
  PapelDaSerie.ajuste => const GrupoDeSeries(
    papel: PapelDaSerie.ajuste,
    series: 1,
    repeticoes: '3',
    descansoSegundos: 90,
  ),
  _ => GrupoDeSeries(
    papel: PapelDaSerie.backoff,
    series: seriesValidas < 2 ? seriesValidas.clamp(1, 2) : 2,
    repeticoes: repsValidas,
    cargaKg: cargaValidas == null ? null : (cargaValidas * 0.8 * 2).round() / 2,
    descansoSegundos: descansoValidas,
  ),
};

/// "2 × 10-15 · Aquecimento · 60 s · 20 kg".
String grupoLinha(GrupoDeSeries g) => [
  '${g.series} × ${g.repeticoes}',
  PapelDaSerie.rotulo(g.papel),
  if (g.descansoSegundos != null) '${g.descansoSegundos} s',
  if (g.cargaKg != null && g.cargaKg! > 0) '${_kg(g.cargaKg!)} kg',
].join(' · ');

/// Resumo de um exercício com grupos: "2 aquec. · 1 ajuste · 3 × 6-10 · 120 s".
/// Com um grupo só (o caso comum), nulo: a linha mostra a prescrição de hoje.
String? resumoDosGrupos(List<SeriePrescrita> linhas, {int? descansoExercicio}) {
  final grupos = agruparSeries(linhas);
  if (grupos.length < 2 && grupos.every((g) => g.papel == PapelDaSerie.valida)) {
    return null;
  }
  final validas = grupos.where((g) => g.papel == PapelDaSerie.valida).toList();
  final partes = <String>[];
  for (final papel in [PapelDaSerie.aquecimento, PapelDaSerie.ajuste]) {
    final n = grupos.where((g) => g.papel == papel).fold(0, (t, g) => t + g.series);
    if (n > 0) partes.add('$n ${PapelDaSerie.curto(papel)}');
  }
  if (validas.isNotEmpty) {
    final total = validas.fold(0, (t, g) => t + g.series);
    partes.add('$total × ${validas.first.repeticoes}');
    final descanso = validas.first.descansoSegundos ?? descansoExercicio;
    if (descanso != null) partes.add('$descanso s');
  }
  final backoff = grupos.where((g) => g.papel == PapelDaSerie.backoff).fold(0, (t, g) => t + g.series);
  if (backoff > 0) partes.add('$backoff ${PapelDaSerie.curto(PapelDaSerie.backoff)}');
  return partes.join(' · ');
}

String _kg(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');

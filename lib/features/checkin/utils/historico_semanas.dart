import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import 'treinos_hub_view.dart';

enum HistoricoSemanaTipo { atual, passada, anterior }

/// Semana ISO (segunda a domingo) no fuso do aparelho, como a meta da Home.
class HistoricoSemana {
  const HistoricoSemana({
    required this.tipo,
    required this.inicio,
    required this.sessoes,
    required this.completa,
  });

  final HistoricoSemanaTipo tipo;

  /// Segunda-feira, 00:00 local.
  final DateTime inicio;
  final List<TreinoRecente> sessoes;

  /// False na semana mais antiga carregada quando há página seguinte: a
  /// contagem ainda pode crescer, então não aparece.
  final bool completa;
}

List<HistoricoSemana> agruparHistoricoPorSemana(
  List<ExecucaoTreino> sessoes, {
  required DateTime now,
  required bool temMais,
}) {
  final porSemana = <DateTime, List<TreinoRecente>>{};
  for (final s in sessoes) {
    final r = treinoRecenteDe(s);
    if (r == null) continue;
    porSemana.putIfAbsent(_segunda(r.quando), () => []).add(r);
  }
  final inicios = porSemana.keys.toList()..sort((a, b) => b.compareTo(a));
  final atual = _segunda(now);
  return [
    for (final (i, inicio) in inicios.indexed)
      HistoricoSemana(
        tipo: switch (_diasEntre(inicio, atual)) {
          0 => HistoricoSemanaTipo.atual,
          7 => HistoricoSemanaTipo.passada,
          _ => HistoricoSemanaTipo.anterior,
        },
        inicio: inicio,
        sessoes: List.unmodifiable(
          porSemana[inicio]!..sort((a, b) => b.quando.compareTo(a.quando)),
        ),
        completa: !(temMais && i == inicios.length - 1),
      ),
  ];
}

/// "Esta semana · 3 treinos"; sem contagem enquanto a semana não veio inteira.
String historicoSemanaCabecalho(S s, HistoricoSemana semana) {
  final titulo = switch (semana.tipo) {
    HistoricoSemanaTipo.atual => s.historicoSemanaAtual,
    HistoricoSemanaTipo.passada => s.historicoSemanaPassada,
    HistoricoSemanaTipo.anterior => s.historicoSemanaDe(semana.inicio),
  };
  if (!semana.completa) return titulo;
  return '$titulo · ${s.historicoSemanaTreinos(semana.sessoes.length)}';
}

DateTime _segunda(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

int _diasEntre(DateTime a, DateTime b) =>
    DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

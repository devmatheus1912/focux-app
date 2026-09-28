import '../data/checkin_repository.dart';

typedef HistoricoFicha = ({int treinoId, String nome});

/// Fichas do plano para o filtro. Com uma só, "Todos" e a ficha mostram o
/// mesmo: sem chips.
List<HistoricoFicha> historicoFichasFiltro(List<ExecucaoTreino> treinos) {
  final vistos = <int>{};
  final fichas = [
    for (final t in treinos)
      if (vistos.add(t.treinoId)) (treinoId: t.treinoId, nome: t.treinoNome),
  ];
  return fichas.length < 2 ? const [] : fichas;
}

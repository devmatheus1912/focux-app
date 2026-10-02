import '../data/checkin_repository.dart';
import 'checkin_execucao_estado.dart';
import 'historico_detalhe_view.dart';

enum CheckinResumoComparacaoTipo { mais, menos, igual, primeira }

/// Volume da sessão contra a anterior da mesma ficha.
class CheckinResumoComparacao {
  const CheckinResumoComparacao.mais(int pct)
    : tipo = CheckinResumoComparacaoTipo.mais,
      percentual = pct;
  const CheckinResumoComparacao.menos(int pct)
    : tipo = CheckinResumoComparacaoTipo.menos,
      percentual = pct;
  const CheckinResumoComparacao.igual()
    : tipo = CheckinResumoComparacaoTipo.igual,
      percentual = 0;
  const CheckinResumoComparacao.primeira()
    : tipo = CheckinResumoComparacaoTipo.primeira,
      percentual = 0;

  final CheckinResumoComparacaoTipo tipo;
  final int percentual;

  @override
  bool operator ==(Object other) =>
      other is CheckinResumoComparacao &&
      other.tipo == tipo &&
      other.percentual == percentual;

  @override
  int get hashCode => Object.hash(tipo, percentual);

  @override
  String toString() => 'CheckinResumoComparacao($tipo, $percentual)';
}

/// Abaixo disso (em %) a diferença de volume é ruído: "mesmo volume".
const checkinResumoIgualAte = 2;

class CheckinResumo {
  const CheckinResumo({
    required this.treinoNome,
    required this.seriesFeitas,
    required this.seriesPlanejadas,
    this.duracao,
    this.volumeKg,
    this.comparacao,
    this.recordes = const [],
    this.destaque,
  });

  final String treinoNome;
  final Duration? duracao;
  final int seriesFeitas;
  final int seriesPlanejadas;
  final double? volumeKg;
  final CheckinResumoComparacao? comparacao;
  final List<EvolucaoPerformance> recordes;

  /// Maior ganho de carga da sessão quando não houve recorde.
  final ({String exercicio, double deltaKg})? destaque;

  bool get temNumeros =>
      duracao != null || seriesFeitas > 0 || volumeKg != null;
}

/// Resumo do fim do treino. [concluida] nulo (concluir sem corpo e detalhe
/// falhando) ainda mostra a tela, só com o nome local.
CheckinResumo buildCheckinResumo({
  required ExecucaoTreino? concluida,
  required SessaoEvolucaoDto? evolucao,
  String treinoNomeLocal = 'Treino',
}) {
  if (concluida == null) {
    return CheckinResumo(
      treinoNome: treinoNomeLocal,
      seriesFeitas: evolucao?.seriesFeitas ?? 0,
      seriesPlanejadas: evolucao?.seriesPlanejadas ?? 0,
      volumeKg: _positivo(evolucao?.volumeKg),
      comparacao: _comparacao(evolucao, _positivo(evolucao?.volumeKg)),
    );
  }
  final view = buildHistoricoDetalheView(concluida, evolucao: evolucao);
  final recordes = checkinEvolucoesParaCelebrar(concluida);
  return CheckinResumo(
    treinoNome:
        concluida.treinoNome.trim().isEmpty
            ? treinoNomeLocal
            : concluida.treinoNome.trim(),
    duracao: view.duracao,
    seriesFeitas: view.seriesFeitas,
    seriesPlanejadas: view.seriesPlanejadas,
    volumeKg: view.volumeKg,
    comparacao: _comparacao(evolucao, view.volumeKg),
    recordes: recordes,
    destaque:
        recordes.isEmpty && (view.destaque?.deltaKg ?? 0) > 0
            ? view.destaque
            : null,
  );
}

CheckinResumoComparacao? _comparacao(SessaoEvolucaoDto? evo, double? volume) {
  if (evo == null) return null;
  if (evo.sinal == 'PRIMEIRA') return const CheckinResumoComparacao.primeira();
  final anterior = _positivo(evo.volumeAnteriorKg);
  if (volume == null || anterior == null) return null;
  final pct = ((volume - anterior) / anterior * 100).round();
  if (pct.abs() < checkinResumoIgualAte) {
    return const CheckinResumoComparacao.igual();
  }
  return pct > 0
      ? CheckinResumoComparacao.mais(pct)
      : CheckinResumoComparacao.menos(-pct);
}

double? _positivo(double? v) => v != null && v > 0 ? v : null;

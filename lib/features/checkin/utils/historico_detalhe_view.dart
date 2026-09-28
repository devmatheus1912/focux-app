import '../data/checkin_repository.dart';
import 'treino_ficha_status.dart';
import 'treinos_hub_view.dart';

String historicoDetalhePath(int execucaoId) => '/checkin/historico/$execucaoId';

/// Comparação com a sessão anterior da mesma ficha (evolução da sessão).
enum HistoricoComparacao { melhorou, caiu, manteve, primeira }

class HistoricoExercicioLinha {
  const HistoricoExercicioLinha({
    required this.nome,
    required this.feito,
    required this.seriesFeitas,
    this.seriesPlanejadas,
    this.cargaKg,
    this.deltaCargaKg,
    this.rpe,
    this.dor = false,
    this.cargas = const [],
  });

  final String nome;
  final bool feito;
  final int seriesFeitas;
  final int? seriesPlanejadas;
  final double? cargaKg;

  /// Carga desta sessão menos a da anterior; `null` sem as duas.
  final double? deltaCargaKg;
  final int? rpe;
  final bool dor;

  /// Carga de cada série, para a sparkline.
  final List<double> cargas;
}

typedef HistoricoRecordeLinha =
    ({String exercicio, String mensagem, double? cargaKg});

typedef HistoricoNotaLinha = ({String exercicio, String nota});

class HistoricoDetalheView {
  const HistoricoDetalheView({
    required this.concluida,
    required this.seriesFeitas,
    required this.seriesPlanejadas,
    required this.exerciciosFeitos,
    required this.exercicios,
    required this.recordes,
    required this.notas,
    this.concluidoEm,
    this.duracao,
    this.volumeKg,
    this.comparacao,
    this.destaque,
  });

  final bool concluida;
  final DateTime? concluidoEm;

  /// Só quando plausível ([treinoDuracaoReal]).
  final Duration? duracao;
  final int seriesFeitas;
  final int seriesPlanejadas;
  final int exerciciosFeitos;

  /// Só com carga registrada (> 0).
  final double? volumeKg;
  final HistoricoComparacao? comparacao;
  final ({String exercicio, double deltaKg})? destaque;
  final List<HistoricoExercicioLinha> exercicios;
  final List<HistoricoRecordeLinha> recordes;
  final List<HistoricoNotaLinha> notas;

  int get exerciciosTotal => exercicios.length;
  bool get semSeries => concluida && seriesFeitas == 0;
}

/// Detalhe da sessão; [evolucao] (quando chega) traz volume e comparação do
/// servidor. Sem ela, os números saem das séries do próprio detalhe.
HistoricoDetalheView buildHistoricoDetalheView(
  ExecucaoTreino execucao, {
  SessaoEvolucaoDto? evolucao,
}) {
  final concluida =
      normalizeTreinoStatus(execucao.status) == treinoStatusConcluido;
  final linhas = [for (final e in execucao.exercicios) _linha(e)];
  final seriesLocais = linhas.fold(0, (t, l) => t + l.seriesFeitas);
  final planejadasLocais = linhas.fold(
    0,
    (t, l) => t + (l.seriesPlanejadas ?? 0),
  );
  final seriesFeitas = evolucao?.seriesFeitas ?? seriesLocais;
  final volume = evolucao != null ? evolucao.volumeKg : _volume(execucao);

  return HistoricoDetalheView(
    concluida: concluida,
    concluidoEm: _local(execucao.concluidoEm),
    duracao:
        concluida
            ? treinoDuracaoReal(execucao.iniciadoEm, execucao.concluidoEm)
            : null,
    seriesFeitas: seriesFeitas,
    seriesPlanejadas: evolucao?.seriesPlanejadas ?? planejadasLocais,
    exerciciosFeitos: linhas.where((l) => l.feito).length,
    volumeKg: seriesFeitas > 0 && volume != null && volume > 0 ? volume : null,
    comparacao: _comparacao(evolucao?.sinal),
    destaque: switch ((
      evolucao?.destaqueExercicio,
      evolucao?.destaqueDeltaKg,
    )) {
      (final String nome, final double delta) when nome.trim().isNotEmpty => (
        exercicio: nome.trim(),
        deltaKg: delta,
      ),
      _ => null,
    },
    exercicios: linhas,
    recordes: [
      for (final c in execucao.evolucoesCarga)
        (
          exercicio: c.exercicioNome,
          mensagem: c.mensagem.trim(),
          cargaKg: c.cargaAtualKg > 0 ? c.cargaAtualKg : null,
        ),
      for (final p in execucao.evolucoesPerformance)
        (
          exercicio: p.exercicioNome,
          mensagem: p.mensagem.trim(),
          cargaKg: null,
        ),
    ],
    notas: [
      for (final e in execucao.exercicios)
        if (_nota(e) case final nota?) (exercicio: e.exercicioNome, nota: nota),
    ],
  );
}

HistoricoExercicioLinha _linha(ExecucaoExercicio e) {
  final feitas = e.seriesFeitas > 0 ? e.seriesFeitas : e.seriesDetalhes.length;
  final planejadas = (e.series ?? 0) > 0 ? e.series : null;
  final ultima = e.seriesDetalhes.isEmpty ? null : e.seriesDetalhes.last;
  final carga = _positiva(ultima?.cargaKg) ?? _positiva(e.cargaKg);
  final anterior = _positiva(e.cargaAnteriorKg);
  return HistoricoExercicioLinha(
    nome: e.exercicioNome,
    feito:
        e.concluido || (planejadas == null ? feitas > 0 : feitas >= planejadas),
    seriesFeitas: feitas,
    seriesPlanejadas: planejadas,
    cargaKg: carga,
    deltaCargaKg: carga != null && anterior != null ? carga - anterior : null,
    rpe: e.rpe ?? ultima?.rpe,
    dor: e.dor || e.seriesDetalhes.any((s) => s.dor),
    cargas: [
      for (final s in e.seriesDetalhes)
        if (_positiva(s.cargaKg) case final c?) c,
    ],
  );
}

double? _volume(ExecucaoTreino execucao) {
  var total = 0.0;
  for (final e in execucao.exercicios) {
    for (final s in e.seriesDetalhes) {
      final carga = s.cargaKg;
      final reps = _primeiroNumero(s.repeticoes);
      if (carga != null && reps != null) total += carga * reps;
    }
  }
  return total > 0 ? total : null;
}

HistoricoComparacao? _comparacao(String? sinal) => switch (sinal) {
  'MELHOROU' => HistoricoComparacao.melhorou,
  'CAIU' => HistoricoComparacao.caiu,
  'MANTEVE' => HistoricoComparacao.manteve,
  'PRIMEIRA' => HistoricoComparacao.primeira,
  _ => null,
};

String? _nota(ExecucaoExercicio e) {
  final partes = [
    for (final t in [e.observacoes, e.feedback])
      if (t != null && t.trim().isNotEmpty) t.trim(),
  ];
  return partes.isEmpty ? null : partes.join(' · ');
}

int? _primeiroNumero(String? raw) {
  final m = RegExp(r'\d+').firstMatch(raw ?? '');
  return m == null ? null : int.tryParse(m.group(0)!);
}

double? _positiva(double? v) => v != null && v > 0 ? v : null;

DateTime? _local(String? raw) {
  final t = raw?.trim() ?? '';
  return t.isEmpty ? null : DateTime.tryParse(t)?.toLocal();
}

import '../../treinos/models/metodo_exercicio.dart';
import '../../treinos/utils/grupos_de_serie.dart';
import '../models/checkin_execucao_models.dart';

/// A série N de um exercício na execução, num lugar só: papel e posição no
/// grupo, meta (reps, carga, descanso), técnica que vale nela e o que os
/// campos sugerem. Tela, cartão, bolinhas, "Depois", descanso e "confirmar o
/// resto" leem daqui (auditoria de arquitetura 16/11, A1).
///
/// Tudo sai de `seriesPrescritas` + `seriesFeitas`, que vêm com a execução:
/// com a série guardada sem internet, a próxima já sai certa. Os campos
/// `proxima*` do servidor só valem para backend antigo, sem linhas.
class SerieDeAgora {
  const SerieDeAgora._({
    required this.numero,
    required this.total,
    required this.papel,
    required this.posicao,
    required this.totalDoPapel,
    required this.metaReps,
    required this.metaCarga,
    required this.descanso,
    required this.tecnica,
    required this.progressao,
    required this.cargaSugerida,
    required this.repsSugeridas,
  });

  final int numero;

  /// Séries do exercício (todas, com aquecimento).
  final int? total;

  /// VALIDA, AQUECIMENTO, AJUSTE ou BACKOFF; sem linhas = VALIDA.
  final String papel;

  /// Posição dentro do papel ("Válida 2 de 4"); nulo sem grupos (só válidas).
  final int? posicao;
  final int? totalDoPapel;

  final String? metaReps;
  final double? metaCarga;

  /// Descanso depois desta série (o do grupo dela, senão o do exercício).
  final int? descanso;

  /// Técnica que vale nesta série; [Tecnica.normal] = nenhuma.
  final Tecnica tecnica;

  /// Pirâmide só aparece nas válidas.
  final Progressao progressao;

  final double? cargaSugerida;
  final int? repsSugeridas;

  bool get comGrupos => posicao != null;
  bool get conta => PapelDaSerie.conta(papel);
  bool get temTecnica => tecnica != Tecnica.normal;

  /// "Válida 1 de 4", "Aquecimento 2 de 2"; sem grupos, "Série 2 de 4".
  String get rotulo => comGrupos
      ? '${PapelDaSerie.rotulo(papel)} $posicao de $totalDoPapel'
      : total == null || total! < 1
      ? 'Série $numero'
      : 'Série ${numero.clamp(1, total!)} de $total';

  /// Curto, para botão e "Depois": "válida 1", "aquecimento 2", "série 3".
  String get rotuloCurto => comGrupos
      ? '${PapelDaSerie.rotulo(papel).toLowerCase()} $posicao'
      : 'série $numero';

  /// Na bolinha: "A" (aquecimento e ajuste), "B" (back-off), número da válida.
  String get rotuloDaBolinha => switch (papel) {
    PapelDaSerie.aquecimento || PapelDaSerie.ajuste => 'A',
    PapelDaSerie.backoff => 'B',
    _ => '${posicao ?? numero}',
  };

  static int? _reps(String? texto) =>
      int.tryParse(RegExp(r'\d+').firstMatch(texto ?? '')?.group(0) ?? '');
}

/// A série [numero] (padrão: a próxima a fazer) do exercício [ee].
SerieDeAgora serieDeAgora(ExecucaoExercicio ee, {int? numero}) {
  final n = numero ?? ee.seriesFeitas + 1;
  final linhas = [...ee.seriesPrescritas]..sort((a, b) => a.numero.compareTo(b.numero));
  final linha = linhas.where((l) => l.numero == n).firstOrNull;
  final papel = linha?.papel ?? PapelDaSerie.valida;
  final soValidas = linhas.every((l) => l.papel == PapelDaSerie.valida);
  final doPapel = [for (final l in linhas) if (l.papel == papel) l];

  // Backend antigo, sem linhas: o servidor diz a meta da próxima série.
  final semLinhas = linhas.isEmpty;
  final proximaDoServidor = semLinhas && n == ee.seriesFeitas + 1;
  final metaReps = linha?.repeticoes ??
      (proximaDoServidor ? ee.proximaRepeticoes : null) ??
      ee.repeticoes;
  final metaCarga = linha?.cargaKg ?? (proximaDoServidor ? ee.proximaCargaKg : null) ?? (semLinhas ? ee.cargaKg : null);

  final tecnica = semLinhas
      ? ee.metodo.tecnica
      : linha?.tecnica == null
      ? Tecnica.normal
      : tecnicaDe(linha!.tecnica);

  return SerieDeAgora._(
    numero: n,
    total: ee.series ?? (linhas.isEmpty ? null : linhas.length),
    papel: papel,
    posicao: soValidas || linha == null ? null : doPapel.indexOf(linha) + 1,
    totalDoPapel: soValidas || linha == null ? null : doPapel.length,
    metaReps: metaReps,
    metaCarga: metaCarga,
    descanso: linha?.descansoSegundos ?? ee.descansoSegundos,
    tecnica: tecnica,
    progressao: papel == PapelDaSerie.valida ? ee.metodo.progressao : Progressao.fixa,
    cargaSugerida: _cargaSugerida(ee, n, papel, metaCarga),
    repsSugeridas: SerieDeAgora._reps(metaReps) ?? _repsDaSessaoPassada(ee, n),
  );
}

/// A meta manda. Sem carga prescrita, uma série que conta usa a da mesma
/// série na sessão passada (o aluno progride); aquecimento e ajuste nunca
/// herdam carga de válida. Por último, a série anterior desta sessão.
double? _cargaSugerida(ExecucaoExercicio ee, int n, String papel, double? meta) {
  if (meta != null && meta > 0) return meta;
  final conta = PapelDaSerie.conta(papel);
  if (conta) {
    final passada = ee.seriesAnteriores.where((s) => s.numero == n).firstOrNull?.cargaKg;
    if (passada != null && passada > 0) return passada;
    final doExercicio = ee.cargaKg ?? ee.cargaAnteriorKg;
    if (doExercicio != null && doExercicio > 0) return doExercicio;
  }
  // Mesma papel, logo antes nesta sessão (aquecimento 2 herda o 1).
  final linhas = ee.seriesPrescritas;
  for (var k = n - 1; k >= 1; k--) {
    final papelK = linhas.where((l) => l.numero == k).firstOrNull?.papel ?? PapelDaSerie.valida;
    if (papelK != papel) continue;
    final feita = ee.seriesDetalhes.where((s) => s.numero == k).firstOrNull?.cargaKg;
    if (feita != null && feita > 0) return feita;
  }
  return null;
}

int? _repsDaSessaoPassada(ExecucaoExercicio ee, int n) =>
    SerieDeAgora._reps(ee.seriesAnteriores.where((s) => s.numero == n).firstOrNull?.repeticoes);

/// A série que vem depois desta no mesmo exercício; nula no fim.
SerieDeAgora? serieSeguinte(ExecucaoExercicio ee) {
  final proxima = ee.seriesFeitas + 2;
  final total = ee.series ?? ee.seriesPrescritas.length;
  if (total < 1 || proxima > total) return null;
  return serieDeAgora(ee, numero: proxima);
}

/// "Última vez nesta série": a mesma série da sessão passada; sem par, a última.
({double? cargaKg, int? reps})? ultimaVezDaSerie(ExecucaoExercicio ee, {int? numero}) {
  final anteriores = ee.seriesAnteriores;
  if (anteriores.isEmpty) return null;
  final n = numero ?? ee.seriesFeitas + 1;
  final mesma = anteriores.where((s) => s.numero == n).firstOrNull ??
      anteriores.reduce((a, b) => b.numero > a.numero ? b : a);
  final reps = SerieDeAgora._reps(mesma.repeticoes);
  final carga = (mesma.cargaKg ?? 0) > 0 ? mesma.cargaKg : null;
  if (carga == null && reps == null) return null;
  return (cargaKg: carga, reps: reps);
}


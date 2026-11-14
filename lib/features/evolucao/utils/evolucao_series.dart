import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../../../l10n/pt.dart';
import '../../alunos/utils/aluno360_medida_plausivel.dart';
import '../data/evolucao_repository.dart';

export '../../../core/utils/pt_br_display.dart' show dataCurta;

enum EvolucaoMetrica {
  peso('kg'),
  cintura('cm'),
  quadril('cm'),
  braco('cm'),
  gordura('%'),
  massa('%');

  const EvolucaoMetrica(this.unidade);

  final String unidade;

  String get rotulo => switch (this) {
    EvolucaoMetrica.peso => ptS.evolucaoMetricaPeso,
    EvolucaoMetrica.cintura => ptS.evolucaoMetricaCintura,
    EvolucaoMetrica.quadril => ptS.evolucaoMetricaQuadril,
    EvolucaoMetrica.braco => ptS.evolucaoMetricaBraco,
    EvolucaoMetrica.gordura => ptS.metaGordura,
    EvolucaoMetrica.massa => ptS.metaMassa,
  };

  double? valor(MedidaCorporal m) => switch (this) {
    EvolucaoMetrica.peso => m.peso,
    EvolucaoMetrica.cintura => m.cintura,
    EvolucaoMetrica.quadril => m.quadril,
    EvolucaoMetrica.braco => m.braco,
    EvolucaoMetrica.gordura || EvolucaoMetrica.massa => null,
  };

  /// Código da meta nesta medida.
  String get codigoMeta => switch (this) {
    EvolucaoMetrica.peso => 'PESO',
    EvolucaoMetrica.cintura => 'CINTURA',
    EvolucaoMetrica.quadril => 'QUADRIL',
    EvolucaoMetrica.braco => 'BRACO',
    EvolucaoMetrica.gordura => 'GORDURA',
    EvolucaoMetrica.massa => 'MASSA',
  };
}

enum EvolucaoPeriodo {
  dias30(30),
  dias90(90),
  meses6(180),
  tudo(null);

  const EvolucaoPeriodo(this.dias);

  final int? dias;

  String get rotulo => switch (this) {
    EvolucaoPeriodo.dias30 => ptS.evolucaoPeriodo30,
    EvolucaoPeriodo.dias90 => ptS.evolucaoPeriodo90,
    EvolucaoPeriodo.meses6 => ptS.evolucaoPeriodo6Meses,
    EvolucaoPeriodo.tudo => ptS.evolucaoPeriodoTudo,
  };
}

/// Com dois registros já existe direção.
const evolucaoPontosParaGrafico = 2;

/// Antes disso, ritmo é oscilação.
const evolucaoPontosParaRitmo = 4;

/// A partir daqui a tendência separa evolução de oscilação do dia.
const evolucaoPontosParaTendencia = 7;

/// Da mais antiga para a mais nova. No mesmo dia, vale a ordem de registro.
List<MedidaCorporal> medidasEmOrdem(Iterable<MedidaCorporal> medidas) {
  final lista = [...medidas];
  lista.sort((a, b) {
    final porData = a.data.compareTo(b.data);
    return porData != 0 ? porData : a.id.compareTo(b.id);
  });
  return lista;
}

/// Um ponto por dia, na ordem: o último registro do dia, ou o [maior] (força).
/// Dois registros no mesmo dia viravam um traço vertical no gráfico.
List<PontoGrafico> umPorDia(List<PontoGrafico> serie, {bool maior = false}) {
  final out = <PontoGrafico>[];
  for (final p in serie) {
    final dia = DateTime(p.data.year, p.data.month, p.data.day);
    final ultimo = out.lastOrNull;
    if (ultimo != null &&
        DateTime(ultimo.data.year, ultimo.data.month, ultimo.data.day) == dia) {
      if (!maior || p.valor > ultimo.valor) out[out.length - 1] = p;
    } else {
      out.add(p);
    }
  }
  return out;
}

List<PontoGrafico> serieDaMetrica(
  Iterable<MedidaCorporal> medidas,
  EvolucaoMetrica metrica,
) => umPorDia([
  for (final m in medidasEmOrdem(medidas))
    if (metrica.valor(m) != null && DateTime.tryParse(m.data) != null)
      PontoGrafico(DateTime.parse(m.data), metrica.valor(m)!),
]);

/// Gordura vem das avaliações, em qualquer ordem.
List<PontoGrafico> serieDeGordura(Iterable<PontoGordura> pontos) {
  final serie = [
    for (final p in pontos)
      if (DateTime.tryParse(p.data) != null)
        PontoGrafico(DateTime.parse(p.data), p.valor),
  ];
  serie.sort((a, b) => a.data.compareTo(b.data));
  return umPorDia(serie);
}

/// A série cobre mais de [dias] dias: só então os chips de período mudam algo.
bool serieCobreMaisQue(List<PontoGrafico> serie, int dias) =>
    serie.length >= 2 &&
    serie.last.data.difference(serie.first.data).inDays > dias;

/// Quanto muda por semana. Nulo com poucos registros.
double? ritmoSemanal(List<PontoGrafico> pontos) {
  if (pontos.length < evolucaoPontosParaRitmo) return null;
  final dias = pontos.last.data.difference(pontos.first.data).inDays;
  if (dias < 7) return null;
  return (pontos.last.valor - pontos.first.valor) / dias * 7;
}

/// De 0 a 1: onde o valor está entre o início e o alvo.
double fracaoAteOAlvo(double inicio, double alvo, double atual) {
  if (alvo == inicio) return 0;
  return ((atual - inicio) / (alvo - inicio)).clamp(0.0, 1.0);
}

List<PontoGrafico> pontosDoPeriodo(
  List<PontoGrafico> pontos,
  EvolucaoPeriodo periodo, {
  DateTime? hoje,
}) {
  final dias = periodo.dias;
  if (dias == null) return pontos;
  final corte = (hoje ?? DateTime.now()).subtract(Duration(days: dias));
  return pontos.where((p) => !p.data.isBefore(corte)).toList();
}

/// Média móvel com mais peso no recente. Vazia com poucos pontos.
List<double> tendenciaDe(List<PontoGrafico> pontos) {
  if (pontos.length < evolucaoPontosParaTendencia) return const [];
  const peso = 0.3;
  final saida = <double>[];
  for (final p in pontos) {
    saida.add(
      saida.isEmpty ? p.valor : saida.last + peso * (p.valor - saida.last),
    );
  }
  return saida;
}

String _sinal(double d) => d > 0 ? '+' : (d < 0 ? '−' : '');

/// Gordura e massa magra vêm das avaliações, não da medida.
bool evolucaoMetricaDaAvaliacao(EvolucaoMetrica m) =>
    m == EvolucaoMetrica.gordura || m == EvolucaoMetrica.massa;

/// Primeiro e último iguais, mas a série mudou no caminho (20% → 15% → 20%).
bool serieVoltouAoInicio(List<PontoGrafico> serie) =>
    serie.length >= 3 &&
    serie.last.valor == serie.first.valor &&
    serie.any((p) => p.valor != serie.first.valor);

/// Massa magra em % é 100% menos a gordura.
double massaMagraPelaGordura(double gordura) =>
    ((100 - gordura) * 10).round() / 10;

/// Gordura e massa magra (%) somam perto de 100%; com uma só, não há o que checar.
bool composicaoCoerente(double? gordura, double? massa) {
  if (gordura == null || massa == null) return true;
  final soma = gordura + massa;
  return soma >= 98 && soma <= 102;
}

/// "+1,5 kg" ou "=". Sem cor: subir ou descer depende do objetivo.
String diferencaTexto(double diferenca, String unidade) {
  if (diferenca == 0) return ptS.evolucaoSemMudanca;
  return '${_sinal(diferenca)}${formatBrDecimal(diferenca.abs())} $unidade';
}


/// O que o leitor de tela diz no lugar do gráfico.
String resumoDaSerie(EvolucaoMetrica metrica, List<PontoGrafico> pontos) {
  if (pontos.isEmpty) return metrica.rotulo;
  final atual = '${formatBrDecimal(pontos.last.valor)} ${metrica.unidade}';
  final diferenca = pontos.last.valor - pontos.first.valor;
  return ptS.evolucaoResumoSerie(
    metrica.rotulo,
    atual,
    diferencaTexto(diferenca, metrica.unidade),
    dataCurta(pontos.first.data),
  );
}

class ProgressoRecorde {
  const ProgressoRecorde({
    required this.nome,
    required this.melhor,
    required this.inicio,
    required this.historico,
  });

  final String nome;
  final RecordePessoal melhor;
  final RecordePessoal inicio;

  /// Do mais novo para o mais antigo.
  final List<RecordePessoal> historico;

  double get ganhoKg => (melhor.cargaKg ?? 0) - (inicio.cargaKg ?? 0);

}

/// Fórmula de Epley. Nulo fora da faixa em que a estimativa presta.
/// Grupos em que 1RM não faz sentido: core, corpo inteiro, cardio, mobilidade.
const _gruposSemUmRm = {
  'ABDOMEN', 'OBLIQUO', 'LOMBAR', 'FULL_BODY', 'CARDIO', 'MOBILIDADE',
};

/// Exercício de core, peso do corpo ou mobilidade. Vale o grupo muscular que
/// o servidor manda; sem ele (exercício digitado à mão), decide pelo nome.
bool exercicioSemUmRm(String nome, {String? grupoMuscular}) {
  if (grupoMuscular != null) return _gruposSemUmRm.contains(grupoMuscular);
  final n = nome.toLowerCase();
  const termos = [
    'abdominal', 'abdômen', 'abdomen', 'prancha', 'crunch', 'sit-up',
    'alongamento', 'mobilidade', 'polichinelo', 'burpee',
  ];
  return termos.any(n.contains);
}

double? umRmEstimado(RecordePessoal r) {
  final carga = r.cargaKg;
  final reps = r.repeticoes;
  if (carga == null || reps == null || reps < 2 || reps > 12) return null;
  if (exercicioSemUmRm(r.exercicioNome, grupoMuscular: r.grupoMuscular)) return null;
  return carga * (1 + reps / 30);
}

/// Um por exercício, com a maior carga em cima.
List<ProgressoRecorde> progressoDosRecordes(List<RecordePessoal> lista) {
  final porExercicio = <String, List<RecordePessoal>>{};
  for (final r in lista) {
    porExercicio.putIfAbsent(r.exercicioNome.trim().toLowerCase(), () => []).add(r);
  }
  final saida = [
    for (final grupo in porExercicio.values)
      () {
        final historico = [...grupo]
          ..sort((a, b) {
            final porData = b.data.compareTo(a.data);
            return porData != 0 ? porData : b.id.compareTo(a.id);
          });
        final melhor = grupo.reduce(
          (a, b) => (b.cargaKg ?? 0) > (a.cargaKg ?? 0) ? b : a,
        );
        return ProgressoRecorde(
          nome: melhor.exercicioNome,
          melhor: melhor,
          inicio: historico.last,
          historico: historico,
        );
      }(),
  ];
  saida.sort(
    (a, b) => (b.melhor.cargaKg ?? 0).compareTo(a.melhor.cargaKg ?? 0),
  );
  return saida;
}

/// Maior ganho entre os exercícios com mais de um registro.
ProgressoRecorde? maiorProgresso(List<ProgressoRecorde> lista) {
  ProgressoRecorde? maior;
  for (final p in lista) {
    if (p.ganhoKg > 0 && (maior == null || p.ganhoKg > maior.ganhoKg)) {
      maior = p;
    }
  }
  return maior;
}

/// O que mudou demais desde o último registro ("Peso +20,0 kg em 5 dias"),
/// pela regra de [variacaoSuspeita]. Vazia quando está tudo plausível.
List<String> variacoesSuspeitas({
  required String data,
  required List<MedidaCorporal> medidas,
  List<PontoGordura> gordura = const [],
  List<PontoGordura> massa = const [],
  double? peso,
  double? cintura,
  double? quadril,
  double? braco,
  double? percGordura,
  double? percMassa,
}) {
  final dia = DateTime.tryParse(data);
  if (dia == null) return const [];
  String? checar(String rotulo, String unidade, double? novo, PontoGrafico? ultimo) {
    if (novo == null || ultimo == null) return null;
    final diferenca = novo - ultimo.valor;
    final dias = dia.difference(ultimo.data).inDays.abs();
    if (!variacaoSuspeita(unidade, diferenca, dias)) return null;
    return ptS.evolucaoVariacaoItem(
      rotulo,
      diferencaTexto(diferenca, unidade == '%' ? 'pp' : unidade),
      dias < 1 ? 1 : dias,
    );
  }

  final novos = {
    EvolucaoMetrica.peso: peso,
    EvolucaoMetrica.cintura: cintura,
    EvolucaoMetrica.quadril: quadril,
    EvolucaoMetrica.braco: braco,
  };
  return [
    for (final MapEntry(key: m, value: novo) in novos.entries)
      if (checar(m.rotulo, m.unidade, novo, serieDaMetrica(medidas, m).lastOrNull)
          case final item?)
        item,
    if (checar(ptS.metaGordura, '%', percGordura, serieDeGordura(gordura).lastOrNull)
        case final item?)
      item,
    if (checar(ptS.metaMassa, '%', percMassa, serieDeGordura(massa).lastOrNull)
        case final item?)
      item,
  ];
}


/// Índices dos pontos que mudaram demais desde o anterior, pela mesma regra
/// do "Confira" ([variacaoSuspeita]). [pontos] em ordem de data.
Set<int> pontosSuspeitos(
  List<PontoGrafico> pontos,
  String unidade, {
  Set<String> conferidas = const {},
}) => {
  for (var i = 1; i < pontos.length; i++)
    if (!conferidas.contains(pontos[i].data.toIso8601String().substring(0, 10)) &&
        variacaoSuspeita(
      unidade,
      pontos[i].valor - pontos[i - 1].valor,
      pontos[i].data.difference(pontos[i - 1].data).inDays.abs(),
    ))
      i,
};

/// Datas (aaaa-mm-dd) com registro conferido pelo personal ("Está certo"):
/// o salto até elas não pede mais "Confira".
Set<String> datasConferidas(
  List<MedidaCorporal> medidas, {
  List<PontoGordura> gordura = const [],
  List<PontoGordura> massa = const [],
}) => {
  for (final m in medidas)
    if (m.conferidoEm != null && m.data.length >= 10) m.data.substring(0, 10),
  for (final p in [...gordura, ...massa])
    if (p.conferido && p.data.length >= 10) p.data.substring(0, 10),
};

/// O registro mais novo de alguma medida saltou demais e ninguém conferiu:
/// antes de mandar o resumo no chat, pede para conferir.
bool ultimaMedidaSuspeita(List<MedidaCorporal> medidas) {
  final conferidas = datasConferidas(medidas);
  for (final m in EvolucaoMetrica.values) {
    final pontos = serieDaMetrica(medidas, m);
    if (pontos.length < 2) continue;
    if (pontosSuspeitos(pontos, m.unidade, conferidas: conferidas)
        .contains(pontos.length - 1)) {
      return true;
    }
  }
  return false;
}

import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/pt.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../utils/evolucao_series.dart';
import 'evolucao_repository.dart';

const metaMetricas = ['PESO', 'CINTURA', 'QUADRIL', 'BRACO', 'GORDURA', 'MASSA'];

String metaMetricaRotulo(String metrica) => switch (metrica) {
  'PESO' => ptS.evolucaoMetricaPeso,
  'CINTURA' => ptS.evolucaoMetricaCintura,
  'QUADRIL' => ptS.evolucaoMetricaQuadril,
  'BRACO' => ptS.evolucaoMetricaBraco,
  'MASSA' => ptS.metaMassa,
  _ => ptS.metaGordura,
};

String metaUnidade(String metrica) => switch (metrica) {
  'PESO' => 'kg',
  'GORDURA' || 'MASSA' => '%',
  _ => 'cm',
};

String metaValor(String metrica, double? valor) {
  if (valor == null) return '—';
  final unidade = metaUnidade(metrica);
  return '${formatBrDecimal(valor)}${unidade == '%' ? '%' : ' $unidade'}';
}

class MetaCorporal {
  const MetaCorporal({
    required this.id,
    required this.metrica,
    required this.tipo,
    required this.valorInicial,
    required this.valorAlvo,
    required this.progresso,
    required this.status,
    this.valorAtual,
    this.valorFinal,
    this.prazo,
    this.observacao,
    this.foraDaFaixa = false,
    this.proximoPassoPendente = false,
    this.criadoEm,
    this.concluidaEm,
    this.mantidaEm,
  });

  final int id;
  final String metrica;
  final String tipo;
  final double valorInicial;
  final double valorAlvo;
  final double? valorAtual;
  final double? valorFinal;
  final int progresso;
  final String? prazo;
  final String status;
  final String? observacao;
  final bool foraDaFaixa;
  final bool proximoPassoPendente;
  final DateTime? criadoEm;
  final DateTime? concluidaEm;
  final DateTime? mantidaEm;

  bool get aberta => status == 'ATIVA' || status == 'A_CONFIRMAR';
  bool get aConfirmar => status == 'A_CONFIRMAR';
  bool get concluida => status == 'CONCLUIDA';
  bool get manutencao => tipo == 'MANUTENCAO';

  static DateTime? _data(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  factory MetaCorporal.fromJson(Map<String, dynamic> j) => MetaCorporal(
    id: (j['id'] as num).toInt(),
    metrica: j['metrica'] as String? ?? 'PESO',
    tipo: j['tipo'] as String? ?? 'META',
    valorInicial: (j['valorInicial'] as num?)?.toDouble() ?? 0,
    valorAlvo: (j['valorAlvo'] as num?)?.toDouble() ?? 0,
    valorAtual: (j['valorAtual'] as num?)?.toDouble(),
    valorFinal: (j['valorFinal'] as num?)?.toDouble(),
    progresso: (j['progresso'] as num?)?.toInt() ?? 0,
    prazo: j['prazo'] as String?,
    status: j['status'] as String? ?? 'ATIVA',
    observacao: j['observacao'] as String?,
    foraDaFaixa: j['foraDaFaixa'] as bool? ?? false,
    proximoPassoPendente: j['proximoPassoPendente'] as bool? ?? false,
    criadoEm: _data(j['criadoEm']),
    concluidaEm: _data(j['concluidaEm']),
    mantidaEm: _data(j['mantidaEm']),
  );
}

enum RumoDaMeta { noRumo, seAfastando }

/// Para onde a medida andou desde o início da meta. Nulo sem meta aberta,
/// sem direção (alvo igual ao início) ou sem mudança. Manutenção vale pela
/// faixa: dentro está no rumo, fora está se afastando.
RumoDaMeta? rumoDaMeta(MetaCorporal? meta, double atual) {
  if (meta == null || !meta.aberta) return null;
  if (meta.manutencao) {
    return meta.foraDaFaixa ? RumoDaMeta.seAfastando : RumoDaMeta.noRumo;
  }
  final sentido = meta.valorAlvo - meta.valorInicial;
  final andou = atual - meta.valorInicial;
  if (sentido == 0 || andou == 0) return null;
  return (sentido > 0) == (andou > 0) ? RumoDaMeta.noRumo : RumoDaMeta.seAfastando;
}

enum ConquistaTipo { meta, mantido, recorde }

class Conquista {
  const Conquista({
    required this.chave,
    required this.tipo,
    required this.titulo,
    required this.detalhe,
    required this.data,
    required this.valor,
  });

  /// O número que vai no centro do selo ("−8,0 kg", "60,0 kg", "82,0 kg").
  final String valor;

  /// Para celebrar uma vez só.
  final String chave;
  final ConquistaTipo tipo;
  final String titulo;
  final String detalhe;
  final DateTime data;

  bool get celebra => tipo != ConquistaTipo.recorde;

  /// "Meta batida", "Meta mantida", "Novo recorde".
  String get tipoRotulo => switch (tipo) {
    ConquistaTipo.meta => ptS.conquistaTipoMeta,
    ConquistaTipo.mantido => ptS.conquistaTipoMantido,
    ConquistaTipo.recorde => ptS.conquistaTipoRecorde,
  };
}


/// Mais recente primeiro. Tudo sai de metas e recordes: selo não tem tabela.
/// Série da medida da meta (peso e circunferências das medidas; gordura e
/// massa das avaliações).
List<PontoGrafico> serieDaMetaCorporal(
  String metrica, {
  List<MedidaCorporal> medidas = const [],
  List<PontoGordura> gordura = const [],
  List<PontoGordura> massa = const [],
}) => switch (metrica) {
  'GORDURA' => serieDeGordura(gordura),
  'MASSA' => serieDeGordura(massa),
  _ => switch (EvolucaoMetrica.values.where((e) => e.codigoMeta == metrica).firstOrNull) {
    final e? => serieDaMetrica(medidas, e),
    null => const [],
  },
};

/// Da medida que deu o valor inicial à que concluiu a meta: quantos dias
/// passaram (pelas datas das medidas, não da meta) e se algum passo no meio
/// pede "Confira". Nulo quando a série não tem os dois pontos.
({int dias, bool suspeito})? trechoDaMeta(MetaCorporal m, List<PontoGrafico> serie) {
  final concluida = m.concluidaEm;
  if (concluida == null || serie.length < 2) return null;
  final final_ = m.valorFinal ?? m.valorAlvo;
  bool igual(double a, double b) => (a - b).abs() < 0.05;
  final dia = DateTime(concluida.year, concluida.month, concluida.day);
  final fim = serie.lastIndexWhere(
    (p) => !p.data.isAfter(dia) && igual(p.valor, final_),
  );
  if (fim < 1) return null;
  var inicio = serie.sublist(0, fim).lastIndexWhere((p) => igual(p.valor, m.valorInicial));
  if (inicio < 0) {
    final criado = m.criadoEm;
    if (criado == null) return null;
    inicio = serie.sublist(0, fim).lastIndexWhere((p) => !p.data.isAfter(criado));
    if (inicio < 0) return null;
  }
  final suspeitos = pontosSuspeitos(serie, metaUnidade(m.metrica));
  return (
    dias: serie[fim].data.difference(serie[inicio].data).inDays,
    suspeito: suspeitos.any((i) => i > inicio && i <= fim),
  );
}

List<Conquista> conquistasDe(
  List<MetaCorporal> metas,
  List<RecordePessoal> recordes, {
  List<MedidaCorporal> medidas = const [],
  List<PontoGordura> gordura = const [],
  List<PontoGordura> massa = const [],
}) {
  final lista = <Conquista>[];
  for (final m in metas) {
    final concluida = m.concluidaEm;
    if (m.concluida && concluida != null && !m.manutencao) {
      final final_ = m.valorFinal ?? m.valorAlvo;
      final trecho = trechoDaMeta(
        m,
        serieDaMetaCorporal(m.metrica, medidas: medidas, gordura: gordura, massa: massa),
      );
      // Salto que pede "Confira" não vira conquista; a meta segue concluída.
      if (trecho?.suspeito ?? false) continue;
      final dif = final_ - m.valorInicial;
      final dias =
          trecho?.dias ??
          (m.criadoEm == null ? 0 : concluida.difference(m.criadoEm!).inDays);
      final unidade = metaUnidade(m.metrica);
      final valor =
          '${dif > 0 ? '+' : '−'}${formatBrDecimal(dif.abs())}${unidade == '%' ? '%' : ' $unidade'}';
      lista.add(
        Conquista(
          chave: 'meta_${m.id}',
          tipo: ConquistaTipo.meta,
          titulo: valor,
          valor: valor,
          detalhe: ptS.conquistaMetaDetalhe(
            metaMetricaRotulo(m.metrica),
            metaValor(m.metrica, m.valorInicial),
            metaValor(m.metrica, final_),
            dias,
          ),
          data: concluida,
        ),
      );
    }
    final mantida = m.mantidaEm;
    if (mantida != null) {
      lista.add(
        Conquista(
          chave: 'mantido_${m.id}',
          tipo: ConquistaTipo.mantido,
          titulo: ptS.conquistaMantidoTitulo,
          valor: metaValor(m.metrica, m.valorAlvo),
          detalhe: ptS.conquistaMantidoDetalhe(metaValor(m.metrica, m.valorAlvo)),
          data: mantida,
        ),
      );
    }
  }
  final porExercicio = <String, List<RecordePessoal>>{};
  for (final r in recordes) {
    porExercicio.putIfAbsent(r.exercicioNome.trim().toLowerCase(), () => []).add(r);
  }
  for (final grupo in porExercicio.values) {
    final ordem = [...grupo]..sort((a, b) => a.data.compareTo(b.data));
    double? melhor;
    for (final r in ordem) {
      final carga = r.cargaKg;
      final data = DateTime.tryParse(r.data);
      if (carga == null || data == null) continue;
      if (melhor != null && carga > melhor) {
        lista.add(
          Conquista(
            chave: 'recorde_${r.id}',
            tipo: ConquistaTipo.recorde,
            titulo: formatBrKg(carga),
            valor: formatBrKg(carga),
            detalhe: ptS.conquistaRecordeDetalhe(r.exercicioNome, dataCurta(data)),
            data: data,
          ),
        );
      }
      if (melhor == null || carga > melhor) melhor = carga;
    }
  }
  lista.sort((a, b) => b.data.compareTo(a.data));
  return lista;
}

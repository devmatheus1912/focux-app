import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';

enum EvolucaoHubView { medidas, recordes, fotos, comparativo }

List<({String value, String label})> get evolucaoDetalheSecoes => [
  (value: 'medidas', label: ptS.evolucaoAbaCorpo),
  (value: 'recordes', label: ptS.evolucaoAbaForca),
  (value: 'fotos', label: ptS.evolucaoAbaFotos),
  (value: 'comparativo', label: ptS.evolucaoAbaComparar),
];

EvolucaoHubView evolucaoHubViewFromSecao(String value) =>
    EvolucaoHubView.values.asNameMap()[value] ?? EvolucaoHubView.medidas;

bool evolucaoMedidaTemConteudo(MedidaCorporal medida) {
  return medida.peso != null ||
      medida.cintura != null ||
      medida.quadril != null ||
      medida.braco != null;
}

String evolucaoMedidaSubtitle(MedidaCorporal medida) {
  final parts = <String>[];
  if (medida.peso != null) {
    parts.add(formatBrKg(medida.peso!));
  }
  if (medida.cintura != null) {
    parts.add('Cintura ${formatBrCm(medida.cintura!)}');
  }
  if (medida.quadril != null) {
    parts.add('Quadril ${formatBrCm(medida.quadril!)}');
  }
  if (medida.braco != null) {
    parts.add('Braço ${formatBrCm(medida.braco!)}');
  }
  if (parts.isNotEmpty) return parts.join(' · ');
  // Só chega aqui se a lista não filtrou por [evolucaoMedidaTemConteudo].
  return 'Registro sem valores';
}


/// Uma data do histórico: a medida e a composição (gordura e massa magra da
/// avaliação) do mesmo dia. Composição sem medida no dia vira linha própria.
typedef RegistroDoHistorico = ({
  String data,
  MedidaCorporal? medida,
  PontoGordura? gordura,
  PontoGordura? massa,
});

/// Mais novo primeiro. A composição entra na medida mais recente do dia.
List<RegistroDoHistorico> registrosDoHistorico(
  List<MedidaCorporal> medidas, {
  List<PontoGordura> gordura = const [],
  List<PontoGordura> massa = const [],
}) {
  String dia(String data) => data.length >= 10 ? data.substring(0, 10) : data;
  final gorduraDoDia = {for (final g in gordura) dia(g.data): g};
  final massaDoDia = {for (final m in massa) dia(m.data): m};
  final usados = <String>{};
  final saida = <RegistroDoHistorico>[];
  for (final m in medidas) {
    final d = dia(m.data);
    final primeira = usados.add(d);
    saida.add((
      data: d,
      medida: m,
      gordura: primeira ? gorduraDoDia[d] : null,
      massa: primeira ? massaDoDia[d] : null,
    ));
  }
  for (final d in {...gorduraDoDia.keys, ...massaDoDia.keys}) {
    if (usados.contains(d)) continue;
    saida.add((data: d, medida: null, gordura: gorduraDoDia[d], massa: massaDoDia[d]));
  }
  saida.sort((a, b) => b.data.compareTo(a.data));
  return saida;
}

/// "110,0 kg · Cintura 70,0 cm · Gordura 20,0% · Massa magra 80,0%".
String evolucaoRegistroSubtitle(RegistroDoHistorico r) => [
  if (r.medida case final m? when evolucaoMedidaTemConteudo(m)) evolucaoMedidaSubtitle(m),
  if (r.gordura case final g?) '${ptS.metaGordura} ${formatBrDecimal(g.valor)}%',
  if (r.massa case final m?) '${ptS.metaMassa} ${formatBrDecimal(m.valor)}%',
].join(' · ');

String evolucaoRegistroLabel(RegistroDoHistorico r) {
  final d = DateTime.tryParse(r.data);
  return d == null ? r.data : fxDateShort(d);
}

String evolucaoRecordeSubtitle(RecordePessoal recorde) {
  final parts = <String>[];
  if (recorde.cargaKg != null) {
    parts.add(formatBrKg(recorde.cargaKg!));
  }
  if (recorde.repeticoes != null) {
    parts.add('${recorde.repeticoes} reps');
  }
  try {
    parts.add(fxDateShort(DateTime.parse(recorde.data)));
  } catch (_) {
    parts.add(recorde.data);
  }
  return parts.join(' · ');
}

String? evolucaoAutorLabel(String? autor) => switch (autor) {
  'ALUNO' => ptS.evolucaoAutorAluno,
  _ => null,
};

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho',
  'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String evolucaoMesAno(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';

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

String evolucaoMedidaLabel(MedidaCorporal medida) {
  try {
    return fxDateShort(DateTime.parse(medida.data));
  } catch (_) {
    return medida.data;
  }
}

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
  'PERSONAL' => ptS.evolucaoAutorPersonal,
  _ => null,
};

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho',
  'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String evolucaoMesAno(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';

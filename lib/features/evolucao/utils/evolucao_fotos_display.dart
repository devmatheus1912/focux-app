import '../../../core/utils/fx_utils.dart';
import '../data/evolucao_repository.dart';
import 'evolucao_display.dart';

String evolucaoFotosCountLabel(int count) {
  if (count <= 0) return 'Nenhuma foto';
  if (count == 1) return '1 foto';
  return '$count fotos';
}

String evolucaoFotosDateLabel(String data) {
  final parsed = DateTime.tryParse(data);
  if (parsed != null) return fxDateShort(parsed);
  return data.length >= 10 ? data.substring(0, 10) : data;
}

/// Na ordem recebida, da mais nova para a mais antiga.
List<(String, List<FotoEvolucao>)> fotosPorMes(List<FotoEvolucao> fotos) {
  final grupos = <String, List<FotoEvolucao>>{};
  for (final f in fotos) {
    final data = DateTime.tryParse(f.data);
    grupos.putIfAbsent(data == null ? f.data : evolucaoMesAno(data), () => []).add(f);
  }
  return [for (final e in grupos.entries) (e.key, e.value)];
}

import '../../../core/utils/pt_br_display.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercicio_repository.dart';

/// Meta curta e legível para linhas da biblioteca (Perfil inset).
String exerciseLibraryMeta(Exercicio exercicio, {bool alreadyInTreino = false}) {
  final parts = <String>[
    if (exercicio.grupoMuscularPrimario != null)
      TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!] ??
          displayMetaToken(exercicio.grupoMuscularPrimario!.backendName),
    if (exercicio.grupoMuscularPrimario == null &&
        exercicio.primaryGroupLabel?.trim().isNotEmpty == true)
      displayMetaToken(exercicio.primaryGroupLabel!),
    if (exercicio.equipamentos.isNotEmpty)
      exercicio.equipamentos
          .take(2)
          .map((e) => TaxonomyLabels.equipamento[e])
          .whereType<String>()
          .join(' · '),
    if (exercicio.equipamentos.isEmpty &&
        exercicio.equipamento?.trim().isNotEmpty == true)
      displayMetaToken(exercicio.equipamento!),
    if (exercicio.dificuldade != null)
      TaxonomyLabels.dificuldade[exercicio.dificuldade!] ??
          displayMetaToken(exercicio.dificuldade!.backendName),
  ];
  final clean = parts.where((e) => e.isNotEmpty).toList();
  final meta = clean.isEmpty ? 'Sem detalhes' : clean.take(3).join(' · ');
  if (alreadyInTreino) {
    return '$meta · No treino';
  }
  return meta;
}

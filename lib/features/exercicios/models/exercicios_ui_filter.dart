import '../data/enums.dart';

/// Busca e filtros da aba Exercícios (20/11): nome, grupo e equipamento. A
/// escolha Meus · Biblioteca · Favoritos fica à parte (`ExerciciosAba`).
class ExerciciosUiFilter {
  final String query;
  final GrupoMuscular? grupo;
  final Equipamento? equipamento;

  const ExerciciosUiFilter({this.query = '', this.grupo, this.equipamento});

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasActive => hasQuery || grupo != null || equipamento != null;

  ExerciciosUiFilter copyWith({
    String? query,
    GrupoMuscular? grupo,
    Equipamento? equipamento,
    bool clearGrupo = false,
    bool clearEquipamento = false,
  }) {
    return ExerciciosUiFilter(
      query: query ?? this.query,
      grupo: clearGrupo ? null : (grupo ?? this.grupo),
      equipamento: clearEquipamento ? null : (equipamento ?? this.equipamento),
    );
  }
}

import 'exercicio_repository.dart';

/// Metadados de paginação — paridade com `Pagina` / picker.
class ExercicioPageMeta {
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  const ExercicioPageMeta({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  factory ExercicioPageMeta.fromJson(Map<String, dynamic> j) => ExercicioPageMeta(
    page: (j['page'] as num?)?.toInt() ?? 0,
    size: (j['size'] as num?)?.toInt() ?? 0,
    totalElements: (j['totalElements'] as num?)?.toInt() ?? 0,
    totalPages: (j['totalPages'] as num?)?.toInt() ?? 0,
    hasNext: j['hasNext'] as bool? ?? false,
  );
}

class ExercicioPage {
  final List<Exercicio> content;
  final ExercicioPageMeta meta;

  const ExercicioPage({required this.content, required this.meta});
}

class ExercicioPickerPage {
  final List<Exercicio> content;
  final ExercicioPageMeta meta;

  const ExercicioPickerPage({required this.content, required this.meta});
}

class ExercicioPickerStats {
  final int total;
  final Map<String, int> porGrupo;

  const ExercicioPickerStats({
    required this.total,
    required this.porGrupo,
  });

  factory ExercicioPickerStats.fromJson(Map<String, dynamic> j) {
    int parseCount(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    Map<String, int> parseMap(dynamic raw) {
      if (raw is! Map) return const {};
      return raw.map(
        (key, value) => MapEntry(key.toString(), parseCount(value)),
      );
    }

    return ExercicioPickerStats(
      total: (j['total'] as num?)?.toInt() ?? 0,
      porGrupo: parseMap(j['porGrupo']),
    );
  }
}

/// Converte item slim do BFF picker para [Exercicio] usado na UI.
Exercicio exercicioFromPickerJson(Map<String, dynamic> json) =>
    Exercicio.fromJson(json);

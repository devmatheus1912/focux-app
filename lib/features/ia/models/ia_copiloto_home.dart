import '../../planos/data/planos_repository.dart';

class IaCopilotoAlunoResumo {
  final int id;
  final String nome;
  final String? objetivo;

  const IaCopilotoAlunoResumo({
    required this.id,
    required this.nome,
    this.objetivo,
  });

  factory IaCopilotoAlunoResumo.fromJson(Map<String, dynamic> json) {
    return IaCopilotoAlunoResumo(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      objetivo: json['objetivo'] as String?,
    );
  }
}

/// BFF `GET /api/ia/copiloto/home` — picker + quota, sem insights gerados.
class IaCopilotoHomeBundle {
  final List<IaCopilotoAlunoResumo> alunosResumo;
  final PlanoFeatures? planoFeatures;

  const IaCopilotoHomeBundle({
    required this.alunosResumo,
    this.planoFeatures,
  });

  factory IaCopilotoHomeBundle.fromJson(Map<String, dynamic> json) {
    final alunosRaw = json['alunosResumo'] as List<dynamic>? ?? const [];
    final planoRaw = json['planoFeatures'];
    return IaCopilotoHomeBundle(
      alunosResumo:
          alunosRaw
              .whereType<Map>()
              .map(
                (row) => IaCopilotoAlunoResumo.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(growable: false),
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
    );
  }
}

import '../../alertas/data/alertas_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../planos/data/planos_repository.dart';
import 'aluno_core_models.dart';

class AlunosHomePageMeta {
  const AlunosHomePageMeta({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  factory AlunosHomePageMeta.fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) {
      return const AlunosHomePageMeta(
        page: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        hasNext: false,
      );
    }
    return AlunosHomePageMeta(
      page: (j['page'] as num?)?.toInt() ?? 0,
      size: (j['size'] as num?)?.toInt() ?? 0,
      totalElements: (j['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (j['totalPages'] as num?)?.toInt() ?? 0,
      hasNext: j['hasNext'] as bool? ?? false,
    );
  }
}

class AlunosHomeBundle {
  static const fallbackDiasSemTreino = 7;
  static const fallbackAderenciaMinima = 50;

  final List<Aluno> alunos;
  final AlunosStats stats;
  final AlertasConfiguracao alertasConfig;
  final AlunosHomePageMeta page;
  final PlanoFeatures? planoFeatures;

  const AlunosHomeBundle({
    required this.alunos,
    required this.stats,
    required this.alertasConfig,
    this.page = const AlunosHomePageMeta(
      page: 0,
      size: 0,
      totalElements: 0,
      totalPages: 0,
      hasNext: false,
    ),
    this.planoFeatures,
  });

  AlunosHomeBundle appendAlunos(AlunosHomeBundle next) => AlunosHomeBundle(
    alunos: [...alunos, ...next.alunos],
    stats: stats,
    alertasConfig: alertasConfig,
    page: AlunosHomePageMeta(
      page: next.page.page,
      size: next.page.size,
      totalElements: next.page.totalElements,
      totalPages: next.page.totalPages,
      hasNext: next.page.hasNext,
    ),
    planoFeatures: planoFeatures ?? next.planoFeatures,
  );

  factory AlunosHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    return AlunosHomeBundle(
      alunos:
          ((j['alunos'] as List?) ?? const [])
              .map((e) => Aluno.fromJson(e as Map<String, dynamic>))
              .toList(),
      stats: AlunosStats.fromJson(
        (j['stats'] as Map<String, dynamic>?) ?? const {},
      ),
      alertasConfig: AlertasConfiguracao.fromJson(
        (j['alertasConfig'] as Map<String, dynamic>?) ??
            const {
              'diasSemTreino': fallbackDiasSemTreino,
              'aderenciaMinima': fallbackAderenciaMinima,
            },
      ),
      page: AlunosHomePageMeta.fromJson(j['page'] as Map<String, dynamic>?),
      planoFeatures:
          planoRaw is Map<String, dynamic>
              ? PlanoFeatures.fromJson(planoRaw)
              : null,
    );
  }
}

/// BFF `GET /api/aluno/perfil/home` — perfil + medidas em um round-trip.
class AlunoPerfilHomeBundle {
  final Aluno aluno;
  final List<MedidaCorporal> medidas;
  final int? completionPercent;
  final DateTime fetchedAt;

  AlunoPerfilHomeBundle({
    required this.aluno,
    required this.medidas,
    this.completionPercent,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory AlunoPerfilHomeBundle.fromJson(Map<String, dynamic> json) {
    final alunoJson = json['aluno'];
    if (alunoJson is! Map<String, dynamic>) {
      throw const FormatException('aluno ausente em /api/aluno/perfil/home');
    }
    return AlunoPerfilHomeBundle(
      aluno: Aluno.fromJson(alunoJson),
      medidas:
          ((json['medidas'] as List?) ?? const [])
              .whereType<Map>()
              .map(
                (row) => MedidaCorporal.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
      completionPercent: json['completionPercent'] as int?,
    );
  }
}

import 'ia_copilot_insight.dart';

/// Estado de uma recomendação guardada.
enum CopilotoEstado { pendente, feita, dispensada }

CopilotoEstado copilotoEstadoDe(String? raw) => switch ((raw ?? '').toUpperCase()) {
  'FEITA' => CopilotoEstado.feita,
  'DISPENSADA' => CopilotoEstado.dispensada,
  _ => CopilotoEstado.pendente,
};

String copilotoEstadoApi(CopilotoEstado e) => switch (e) {
  CopilotoEstado.pendente => 'PENDENTE',
  CopilotoEstado.feita => 'FEITA',
  CopilotoEstado.dispensada => 'DISPENSADA',
};

/// Recomendação da análise guardada: o texto da IA e o que o personal fez.
class CopilotoRecomendacao {
  const CopilotoRecomendacao({
    required this.id,
    required this.insight,
    this.estado = CopilotoEstado.pendente,
    this.resultado,
  });

  final int id;
  final IaCopilotInsight insight;
  final CopilotoEstado estado;

  /// `MENSAGEM_ENVIADA`, `TAREFA_CRIADA`…
  final String? resultado;

  bool get pendente => estado == CopilotoEstado.pendente;

  CopilotoRecomendacao copyWith({CopilotoEstado? estado, String? resultado}) =>
      CopilotoRecomendacao(
        id: id,
        insight: insight,
        estado: estado ?? this.estado,
        resultado: estado == CopilotoEstado.pendente ? null : (resultado ?? this.resultado),
      );

  factory CopilotoRecomendacao.fromJson(Map<String, dynamic> j, {int index = 0}) =>
      CopilotoRecomendacao(
        id: (j['id'] as num).toInt(),
        insight: IaCopilotInsight.fromJson(j, index: index),
        estado: copilotoEstadoDe(j['estado'] as String?),
        resultado: j['resultado'] as String?,
      );
}

/// Análise do Copiloto guardada no servidor (`/api/ia/copiloto/analises`).
class CopilotoAnalise {
  const CopilotoAnalise({
    required this.id,
    required this.alunoId,
    required this.recomendacoes,
    this.alunoNome,
    this.criadaEm,
    this.concluidaEm,
    this.motivo,
  });

  final int id;
  final int alunoId;
  final String? alunoNome;
  final DateTime? criadaEm;
  final DateTime? concluidaEm;
  final String? motivo;
  final List<CopilotoRecomendacao> recomendacoes;

  /// A próxima que ainda falta (na ordem da análise).
  CopilotoRecomendacao? get proximaPendente {
    for (final r in recomendacoes) {
      if (r.pendente) return r;
    }
    return null;
  }

  CopilotoAnalise comRecomendacao(CopilotoRecomendacao nova) => CopilotoAnalise(
    id: id,
    alunoId: alunoId,
    alunoNome: alunoNome,
    criadaEm: criadaEm,
    concluidaEm: nova.pendente ? null : concluidaEm,
    motivo: motivo,
    recomendacoes: [
      for (final r in recomendacoes) r.id == nova.id ? nova : r,
    ],
  );

  factory CopilotoAnalise.fromJson(Map<String, dynamic> j) {
    final recs = (j['recomendacoes'] as List? ?? const []);
    return CopilotoAnalise(
      id: (j['id'] as num).toInt(),
      alunoId: (j['alunoId'] as num).toInt(),
      alunoNome: j['alunoNome'] as String?,
      criadaEm: DateTime.tryParse(j['criadaEm']?.toString() ?? ''),
      concluidaEm: DateTime.tryParse(j['concluidaEm']?.toString() ?? ''),
      motivo: j['motivo'] as String?,
      recomendacoes: [
        for (final (i, r) in recs.indexed)
          CopilotoRecomendacao.fromJson(Map<String, dynamic>.from(r as Map), index: i),
      ],
    );
  }
}

/// Linha de "Análises recentes": a mais nova de cada aluno.
class CopilotoAnaliseResumo {
  const CopilotoAnaliseResumo({
    required this.id,
    required this.alunoId,
    required this.total,
    required this.feitas,
    required this.dispensadas,
    this.alunoNome,
    this.criadaEm,
    this.concluidaEm,
  });

  final int id;
  final int alunoId;
  final String? alunoNome;
  final DateTime? criadaEm;
  final DateTime? concluidaEm;
  final int total;
  final int feitas;
  final int dispensadas;

  int get pendentes => total - feitas - dispensadas;

  factory CopilotoAnaliseResumo.fromJson(Map<String, dynamic> j) =>
      CopilotoAnaliseResumo(
        id: (j['id'] as num).toInt(),
        alunoId: (j['alunoId'] as num).toInt(),
        alunoNome: j['alunoNome'] as String?,
        criadaEm: DateTime.tryParse(j['criadaEm']?.toString() ?? ''),
        concluidaEm: DateTime.tryParse(j['concluidaEm']?.toString() ?? ''),
        total: (j['total'] as num?)?.toInt() ?? 0,
        feitas: (j['feitas'] as num?)?.toInt() ?? 0,
        dispensadas: (j['dispensadas'] as num?)?.toInt() ?? 0,
      );
}

class CommandCenterData {
  final List<AgendamentoResumo> agendaHoje;
  final List<AlertaResumo> alunosEmRisco;
  final List<AlunoScoreResumo> alunosScore;
  final List<FilaAcaoResumo> filaAcoes;
  final List<MensalidadeResumo> cobrancasPendentes;
  final List<AutonomiaGargaloResumo> autonomiaGargalos;

  CommandCenterData({
    required this.agendaHoje,
    required this.alunosEmRisco,
    required this.alunosScore,
    required this.filaAcoes,
    required this.cobrancasPendentes,
    required this.autonomiaGargalos,
  });

  factory CommandCenterData.fromJson(Map<String, dynamic> json) {
    return CommandCenterData(
      agendaHoje:
          (json['agendaHoje'] as List?)
              ?.map(
                (e) => AgendamentoResumo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      alunosEmRisco:
          (json['alunosEmRisco'] as List?)
              ?.map((e) => AlertaResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alunosScore:
          (json['alunosScore'] as List?)
              ?.map((e) => AlunoScoreResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      filaAcoes:
          (json['filaAcoes'] as List?)
              ?.map((e) => FilaAcaoResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cobrancasPendentes:
          (json['cobrancasPendentes'] as List?)
              ?.map(
                (e) => MensalidadeResumo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      autonomiaGargalos:
          (json['autonomiaGargalos'] as List?)
              ?.map(
                (e) =>
                    AutonomiaGargaloResumo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class AlunoScoreResumo {
  final int alunoId;
  final String alunoNome;
  final int score;
  final String ritmo;
  final String risco;
  final String proximaAcao;
  final String narrativa;
  final String objetivo;
  final String acaoUrl;
  final String prioridade;
  final bool iaSugerida;
  final int? deltaScore;
  final String? ultimoSnapshotEm;

  AlunoScoreResumo({
    required this.alunoId,
    required this.alunoNome,
    required this.score,
    required this.ritmo,
    required this.risco,
    required this.proximaAcao,
    required this.narrativa,
    required this.objetivo,
    required this.acaoUrl,
    required this.prioridade,
    required this.iaSugerida,
    this.deltaScore,
    this.ultimoSnapshotEm,
  });

  factory AlunoScoreResumo.fromJson(Map<String, dynamic> json) =>
      AlunoScoreResumo(
        alunoId: (json['alunoId'] as num?)?.toInt() ?? 0,
        alunoNome: json['alunoNome'] as String? ?? 'Aluno',
        score: (json['score'] as num?)?.toInt() ?? 0,
        ritmo: json['ritmo'] as String? ?? 'Ritmo em leitura',
        risco: json['risco'] as String? ?? 'Risco baixo',
        proximaAcao: json['proximaAcao'] as String? ?? 'Abrir aluno',
        narrativa: json['narrativa'] as String? ?? '',
        objetivo: json['objetivo'] as String? ?? 'Objetivo indefinido',
        acaoUrl: json['acaoUrl'] as String? ?? '/alunos',
        prioridade: json['prioridade'] as String? ?? 'P2',
        iaSugerida: json['iaSugerida'] as bool? ?? false,
        deltaScore: (json['deltaScore'] as num?)?.toInt(),
        ultimoSnapshotEm: json['ultimoSnapshotEm'] as String?,
      );
}

class FocuxScoreSnapshotResumo {
  final int id;
  final int alunoId;
  final String alunoNome;
  final String dataReferencia;
  final int score;
  final String ritmo;
  final String risco;
  final String proximaAcao;
  final String narrativa;
  final String objetivo;
  final String prioridade;
  final bool iaSugerida;
  final String? criadoEm;

  FocuxScoreSnapshotResumo({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.dataReferencia,
    required this.score,
    required this.ritmo,
    required this.risco,
    required this.proximaAcao,
    required this.narrativa,
    required this.objetivo,
    required this.prioridade,
    required this.iaSugerida,
    this.criadoEm,
  });

  factory FocuxScoreSnapshotResumo.fromJson(Map<String, dynamic> json) =>
      FocuxScoreSnapshotResumo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        alunoId: (json['alunoId'] as num?)?.toInt() ?? 0,
        alunoNome: json['alunoNome'] as String? ?? 'Aluno',
        dataReferencia: json['dataReferencia'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        ritmo: json['ritmo'] as String? ?? 'Ritmo em leitura',
        risco: json['risco'] as String? ?? 'Risco baixo',
        proximaAcao: json['proximaAcao'] as String? ?? 'Abrir aluno',
        narrativa: json['narrativa'] as String? ?? '',
        objetivo: json['objetivo'] as String? ?? 'Objetivo indefinido',
        prioridade: json['prioridade'] as String? ?? 'P2',
        iaSugerida: json['iaSugerida'] as bool? ?? false,
        criadoEm: json['criadoEm'] as String?,
      );
}

class AutonomiaGargaloResumo {
  final int alunoId;
  final String alunoNome;
  final String taskId;
  final String taskTitle;
  final String prioridade;
  final int vistos;
  final int cliques;
  final int concluidos;
  final String ultimaAcao;
  final String? ultimoEventoEm;
  final String acaoUrl;

  AutonomiaGargaloResumo({
    required this.alunoId,
    required this.alunoNome,
    required this.taskId,
    required this.taskTitle,
    required this.prioridade,
    required this.vistos,
    required this.cliques,
    required this.concluidos,
    required this.ultimaAcao,
    required this.ultimoEventoEm,
    required this.acaoUrl,
  });

  factory AutonomiaGargaloResumo.fromJson(Map<String, dynamic> json) =>
      AutonomiaGargaloResumo(
        alunoId: (json['alunoId'] as num?)?.toInt() ?? 0,
        alunoNome: json['alunoNome'] as String? ?? 'Aluno',
        taskId: json['taskId'] as String? ?? '',
        taskTitle: json['taskTitle'] as String? ?? 'Tarefa do aluno',
        prioridade: json['prioridade'] as String? ?? 'MEDIA',
        vistos: (json['vistos'] as num?)?.toInt() ?? 0,
        cliques: (json['cliques'] as num?)?.toInt() ?? 0,
        concluidos: (json['concluidos'] as num?)?.toInt() ?? 0,
        ultimaAcao: json['ultimaAcao'] as String? ?? 'CLICKED',
        ultimoEventoEm: json['ultimoEventoEm'] as String?,
        acaoUrl: json['acaoUrl'] as String? ?? '/alunos',
      );
}

class AgendamentoResumo {
  final int id;
  final String nomeAluno;
  final String horario;
  final String status;

  AgendamentoResumo({
    required this.id,
    required this.nomeAluno,
    required this.horario,
    required this.status,
  });

  factory AgendamentoResumo.fromJson(Map<String, dynamic> json) =>
      AgendamentoResumo(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        horario: json['horario'] as String,
        status: json['status'] as String,
      );
}

class AlertaResumo {
  final int id;
  final String nomeAluno;
  final String motivo;
  final String nivelRisco;

  AlertaResumo({
    required this.id,
    required this.nomeAluno,
    required this.motivo,
    required this.nivelRisco,
  });

  factory AlertaResumo.fromJson(Map<String, dynamic> json) => AlertaResumo(
    id: json['id'] as int,
    nomeAluno: json['nomeAluno'] as String,
    motivo: json['motivo'] as String,
    nivelRisco: json['nivelRisco'] as String,
  );
}

class FilaAcaoResumo {
  final String tipo;
  final String actionKey;
  final String titulo;
  final String descricao;
  final String acaoUrl;
  final String prioridade;
  final String severidade;
  final String responsavel;
  final String sla;
  final String status;
  final String ctaLabel;
  final bool iaSugerida;
  final int? alunoId;
  final String? snoozedUntil;
  final String? resolvedAt;
  final String? createdAt;
  final String? updatedAt;

  FilaAcaoResumo({
    required this.tipo,
    required this.actionKey,
    required this.titulo,
    required this.descricao,
    required this.acaoUrl,
    required this.prioridade,
    required this.severidade,
    required this.responsavel,
    required this.sla,
    required this.status,
    required this.ctaLabel,
    required this.iaSugerida,
    this.alunoId,
    this.snoozedUntil,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory FilaAcaoResumo.fromJson(Map<String, dynamic> json) => FilaAcaoResumo(
    tipo: json['tipo'] as String,
    actionKey: json['actionKey'] as String? ?? json['tipo'] as String,
    titulo: json['titulo'] as String? ?? json['descricao'] as String? ?? '',
    descricao: json['descricao'] as String,
    acaoUrl: json['acaoUrl'] as String,
    prioridade: json['prioridade'] as String? ?? 'P2',
    severidade: json['severidade'] as String? ?? 'MEDIA',
    responsavel: json['responsavel'] as String? ?? 'Personal',
    sla: json['sla'] as String? ?? 'Hoje',
    status: json['status'] as String? ?? 'ABERTO',
    ctaLabel: json['ctaLabel'] as String? ?? 'Abrir',
    iaSugerida: json['iaSugerida'] as bool? ?? false,
    alunoId: (json['alunoId'] as num?)?.toInt(),
    snoozedUntil: json['snoozedUntil'] as String?,
    resolvedAt: json['resolvedAt'] as String?,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );
}

class MensalidadeResumo {
  final int id;
  final String nomeAluno;
  final double valor;
  final String dataVencimento;

  MensalidadeResumo({
    required this.id,
    required this.nomeAluno,
    required this.valor,
    required this.dataVencimento,
  });

  factory MensalidadeResumo.fromJson(Map<String, dynamic> json) =>
      MensalidadeResumo(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        valor: (json['valor'] as num).toDouble(),
        dataVencimento: json['dataVencimento'] as String,
      );
}

class CommandCenterData {
  final List<AgendamentoResumo> agendaHoje;
  final List<AlertaResumo> alunosEmRisco;
  final List<FilaAcaoResumo> filaAcoes;
  final List<MensalidadeResumo> cobrancasPendentes;

  CommandCenterData({
    required this.agendaHoje,
    required this.alunosEmRisco,
    required this.filaAcoes,
    required this.cobrancasPendentes,
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
    );
  }
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

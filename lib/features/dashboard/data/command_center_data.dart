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
      agendaHoje: (json['agendaHoje'] as List?)
              ?.map((e) => AgendamentoResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alunosEmRisco: (json['alunosEmRisco'] as List?)
              ?.map((e) => AlertaResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      filaAcoes: (json['filaAcoes'] as List?)
              ?.map((e) => FilaAcaoResumo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cobrancasPendentes: (json['cobrancasPendentes'] as List?)
              ?.map((e) => MensalidadeResumo.fromJson(e as Map<String, dynamic>))
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

  AgendamentoResumo({required this.id, required this.nomeAluno, required this.horario, required this.status});

  factory AgendamentoResumo.fromJson(Map<String, dynamic> json) => AgendamentoResumo(
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

  AlertaResumo({required this.id, required this.nomeAluno, required this.motivo, required this.nivelRisco});

  factory AlertaResumo.fromJson(Map<String, dynamic> json) => AlertaResumo(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        motivo: json['motivo'] as String,
        nivelRisco: json['nivelRisco'] as String,
      );
}

class FilaAcaoResumo {
  final String tipo;
  final String descricao;
  final String acaoUrl;

  FilaAcaoResumo({required this.tipo, required this.descricao, required this.acaoUrl});

  factory FilaAcaoResumo.fromJson(Map<String, dynamic> json) => FilaAcaoResumo(
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        acaoUrl: json['acaoUrl'] as String,
      );
}

class MensalidadeResumo {
  final int id;
  final String nomeAluno;
  final double valor;
  final String dataVencimento;

  MensalidadeResumo({required this.id, required this.nomeAluno, required this.valor, required this.dataVencimento});

  factory MensalidadeResumo.fromJson(Map<String, dynamic> json) => MensalidadeResumo(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        valor: (json['valor'] as num).toDouble(),
        dataVencimento: json['dataVencimento'] as String,
      );
}

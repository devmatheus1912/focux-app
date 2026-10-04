import '../../dashboard/data/command_center_data.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../health/data/health_repository.dart';
import 'aluno_core_models.dart';

/// Progressive Operação payload — GET `/api/alunos/{id}/360/operacao`.
/// Critical path for Aluno 360 first paint (no monolito `/360`).
class Aluno360Operacao {
  final Aluno aluno;
  final AlunoAutonomiaResumo autonomiaResumo;
  final ProximaAcaoResumo proximaAcao;
  final bool? hasOpenCopilotTask;
  final AderenciaSemanalBundle aderenciaSemanal;
  final bool? hasWearableHistory;
  final RecoverySnapshot? recoverySnapshot;
  final RiscoResumo? riscoResumo;
  final OperacaoUiHints? operacaoUiHints;
  final List<FilaAcaoResumo>? openCopilotTasks;

  const Aluno360Operacao({
    required this.aluno,
    required this.autonomiaResumo,
    required this.proximaAcao,
    this.hasOpenCopilotTask,
    this.aderenciaSemanal = const AderenciaSemanalBundle(),
    this.hasWearableHistory,
    this.recoverySnapshot,
    this.riscoResumo,
    this.operacaoUiHints,
    this.openCopilotTasks,
  });

  factory Aluno360Operacao.fromJson(Map<String, dynamic> json) =>
      Aluno360Operacao(
        aluno: Aluno.fromJson(json['aluno'] as Map<String, dynamic>),
        autonomiaResumo: AlunoAutonomiaResumo.fromJson(
          json['autonomiaResumo'] as Map<String, dynamic>,
        ),
        proximaAcao: ProximaAcaoResumo.fromJson(
          json['proximaAcao'] as Map<String, dynamic>,
        ),
        hasOpenCopilotTask: json['hasOpenCopilotTask'] as bool?,
        aderenciaSemanal: AderenciaSemanalBundle.parse(json['aderenciaSemanal']),
        hasWearableHistory: json['hasWearableHistory'] as bool?,
        recoverySnapshot:
            json['recoverySnapshot'] != null
                ? RecoverySnapshot.fromJson(
                  json['recoverySnapshot'] as Map<String, dynamic>,
                )
                : null,
        riscoResumo:
            json['riscoResumo'] != null
                ? RiscoResumo.fromJson(
                  json['riscoResumo'] as Map<String, dynamic>,
                )
                : null,
        operacaoUiHints:
            json['operacaoUiHints'] != null
                ? OperacaoUiHints.fromJson(
                  json['operacaoUiHints'] as Map<String, dynamic>,
                )
                : null,
        openCopilotTasks:
            json.containsKey('openCopilotTasks')
                ? (json['openCopilotTasks'] as List<dynamic>? ?? const [])
                    .map(
                      (e) =>
                          FilaAcaoResumo.fromJson(e as Map<String, dynamic>),
                    )
                    .toList()
                : null,
      );
}

/// Progressive Evolução payload — GET `/api/alunos/{id}/360/evolucao`.
class Aluno360Evolucao {
  final EvolucaoInteligente evolucaoInteligente;
  final List<Timeline360Event> timelinePreview;

  const Aluno360Evolucao({
    required this.evolucaoInteligente,
    this.timelinePreview = const [],
  });

  factory Aluno360Evolucao.fromJson(Map<String, dynamic> json) =>
      Aluno360Evolucao(
        evolucaoInteligente: EvolucaoInteligente.fromJson(
          json['evolucaoInteligente'] as Map<String, dynamic>,
        ),
        timelinePreview:
            (json['timelinePreview'] as List<dynamic>? ?? const [])
                .map(
                  (e) => Timeline360Event.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}

/// Progressive Ferramentas payload — GET `/api/alunos/{id}/360/ferramentas`.
///
/// Optional [evolucaoHome] mirrors `GET /api/alunos/{id}/evolucao/home`
/// so Medidas can warm without a second round-trip.
///
/// Optional [composicaoResumo] seeds BF / massa tiles without
/// `GET /avaliacoes/comparativo`.
///
/// Optional [anamneseResumo] seeds the Anamnese tile without `GET /anamnese`.
class Aluno360ComposicaoResumo {
  final double? percGordura;
  final double? massaMuscular;

  const Aluno360ComposicaoResumo({
    this.percGordura,
    this.massaMuscular,
  });

  factory Aluno360ComposicaoResumo.fromJson(Map<String, dynamic> json) {
    final massa =
        (json['massaMuscular'] as num?)?.toDouble() ??
        (json['percMassa'] as num?)?.toDouble() ??
        (json['massaMagra'] as num?)?.toDouble();
    return Aluno360ComposicaoResumo(
      percGordura: (json['percGordura'] as num?)?.toDouble(),
      massaMuscular: massa,
    );
  }
}

class Aluno360AnamneseResumo {
  /// Same codes as [AnamneseStatus] (`NAO_INICIADA`, `SOLICITADA`, …).
  final String? status;

  const Aluno360AnamneseResumo({this.status});

  factory Aluno360AnamneseResumo.fromJson(Map<String, dynamic> json) =>
      Aluno360AnamneseResumo(status: json['status'] as String?);
}

class Aluno360Ferramentas {
  final AderenciaSemanalBundle? aderenciaSemanal;
  final bool? hasWearableHistory;
  final EvolucaoHomeBundle? evolucaoHome;
  final Aluno360ComposicaoResumo? composicaoResumo;
  final Aluno360AnamneseResumo? anamneseResumo;

  const Aluno360Ferramentas({
    this.aderenciaSemanal,
    this.hasWearableHistory,
    this.evolucaoHome,
    this.composicaoResumo,
    this.anamneseResumo,
  });

  factory Aluno360Ferramentas.fromJson(Map<String, dynamic> json) {
    final rawHome = json['evolucaoHome'];
    final rawComposicao = json['composicaoResumo'];
    final rawAnamnese = json['anamneseResumo'];
    return Aluno360Ferramentas(
      aderenciaSemanal:
          json['aderenciaSemanal'] != null
              ? AderenciaSemanalBundle.parse(json['aderenciaSemanal'])
              : null,
      hasWearableHistory: json['hasWearableHistory'] as bool?,
      evolucaoHome:
          rawHome is Map<String, dynamic>
              ? EvolucaoHomeBundle.fromJson(rawHome)
              : null,
      composicaoResumo:
          rawComposicao is Map<String, dynamic>
              ? Aluno360ComposicaoResumo.fromJson(rawComposicao)
              : null,
      anamneseResumo:
          rawAnamnese is Map<String, dynamic>
              ? Aluno360AnamneseResumo.fromJson(rawAnamnese)
              : null,
    );
  }
}

class AlunoAutonomiaResumo {
  final int alunoId;
  final int totalEventos;
  final int vistos;
  final int cliques;
  final int concluidos;
  final String? gargaloTaskId;
  final String? gargaloTitulo;
  final String? gargaloPrioridade;
  final String? gargaloUltimaAcao;
  final DateTime? gargaloCriadoEm;

  const AlunoAutonomiaResumo({
    required this.alunoId,
    required this.totalEventos,
    required this.vistos,
    required this.cliques,
    required this.concluidos,
    this.gargaloTaskId,
    this.gargaloTitulo,
    this.gargaloPrioridade,
    this.gargaloUltimaAcao,
    this.gargaloCriadoEm,
  });

  factory AlunoAutonomiaResumo.fromJson(Map<String, dynamic> json) =>
      AlunoAutonomiaResumo(
        alunoId: (json['alunoId'] as num?)?.toInt() ?? 0,
        totalEventos: (json['totalEventos'] as num?)?.toInt() ?? 0,
        vistos: (json['vistos'] as num?)?.toInt() ?? 0,
        cliques: (json['cliques'] as num?)?.toInt() ?? 0,
        concluidos: (json['concluidos'] as num?)?.toInt() ?? 0,
        gargaloTaskId: json['gargaloTaskId'] as String?,
        gargaloTitulo: json['gargaloTitulo'] as String?,
        gargaloPrioridade: json['gargaloPrioridade'] as String?,
        gargaloUltimaAcao: json['gargaloUltimaAcao'] as String?,
        gargaloCriadoEm:
            json['gargaloCriadoEm'] == null
                ? null
                : DateTime.tryParse(json['gargaloCriadoEm'].toString()),
      );
}


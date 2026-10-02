import '../../exercicios/data/enums.dart';
import '../utils/alunos_list_sparkline_logic.dart';

class Aluno {
  final int id;
  final String nome;
  final String email;
  final String? objetivo;
  final String status;
  final String? fotoUrl;
  final bool inadimplente;
  final bool emRisco;
  final String? telefone;
  final String? whatsapp;
  final String? genero;
  final String? tipoConsultoria;
  final String statusFinanceiro;
  final int? scoreProntidao;
  final String? senhaProvisoria;
  final double? peso;
  final double? altura;
  final String? dataNascimento;
  final Set<Equipamento> equipamentosDisponiveis;
  final int? aderenciaPercent;
  final int? diasSemTreino;
  final String? riscoNivel;
  final String? proximoContato;
  final String? snoozedUntil;
  final String? ultimoContato;
  final bool? operacaoFocusMode;
  final List<double> aderenciaSparkline;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    this.objetivo,
    required this.status,
    this.fotoUrl,
    this.inadimplente = false,
    this.emRisco = false,
    this.telefone,
    this.whatsapp,
    this.genero,
    this.tipoConsultoria,
    this.statusFinanceiro = 'ATIVO',
    this.scoreProntidao,
    this.senhaProvisoria,
    this.peso,
    this.altura,
    this.dataNascimento,
    this.equipamentosDisponiveis = const {},
    this.aderenciaPercent,
    this.diasSemTreino,
    this.riscoNivel,
    this.proximoContato,
    this.snoozedUntil,
    this.ultimoContato,
    this.operacaoFocusMode,
    this.aderenciaSparkline = const [],
  });

  DateTime? get followUpDate {
    final raw = proximoContato?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? get snoozedUntilDate => DateTime.tryParse(snoozedUntil ?? '');

  DateTime? get ultimoContatoDate {
    final raw = ultimoContato?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  int? get idade {
    if (dataNascimento == null) return null;
    final nasc = DateTime.tryParse(dataNascimento!);
    if (nasc == null) return null;
    final now = DateTime.now();
    int age = now.year - nasc.year;
    if (now.month < nasc.month ||
        (now.month == nasc.month && now.day < nasc.day)) {
      age--;
    }
    return age;
  }

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String? ?? '',
    objetivo: json['objetivo'] as String?,
    status: json['status'] as String,
    fotoUrl: json['fotoUrl'] as String?,
    inadimplente: json['inadimplente'] as bool? ?? false,
    emRisco: json['emRisco'] as bool? ?? false,
    telefone: json['telefone'] as String?,
    whatsapp: json['whatsapp'] as String?,
    genero: json['genero'] as String?,
    tipoConsultoria: json['tipoConsultoria'] as String?,
    statusFinanceiro: json['statusFinanceiro'] as String? ?? 'ATIVO',
    scoreProntidao: json['scoreProntidao'] as int?,
    senhaProvisoria: json['senhaProvisoria'] as String?,
    peso: json['peso']?.toDouble(),
    altura: json['altura']?.toDouble(),
    dataNascimento: json['dataNascimento'] as String?,
    aderenciaPercent: (json['aderenciaPercent'] as num?)?.toInt(),
    diasSemTreino: (json['diasSemTreino'] as num?)?.toInt(),
    riscoNivel: json['riscoNivel'] as String?,
    proximoContato: json['proximoContato'] as String?,
    snoozedUntil: json['snoozedUntil'] as String?,
    ultimoContato: json['ultimoContato'] as String?,
    operacaoFocusMode: json['operacaoFocusMode'] as bool?,
    aderenciaSparkline: ((json['aderenciaSparkline'] as List?) ?? const [])
        .map((e) {
          final n = (e as num?)?.toDouble();
          if (n == null || !n.isFinite || n <= 0) return 0.0;
          if (n > alunosListSparklineMaxCheckinsPerDay) {
            return alunosListSparklineMaxCheckinsPerDay;
          }
          return n;
        })
        .toList(growable: false),
    equipamentosDisponiveis:
        parseEnumCsv(
          Equipamento.values,
          json['equipamentosDisponiveis'] ??
              json['equipamentosDisponiveisCsv'] ??
              json['equipamentos_disponiveis'],
        ).toSet(),
  );
}

class AlunosStats {
  final int total;
  final int totalAtivos;
  final int totalInadimplentes;
  final int totalRiscoAlto;
  final int totalConvites;
  final int totalContatoHoje;

  /// INATIVO + BLOQUEADO. `null` enquanto o BFF não manda o campo.
  final int? totalInativos;

  const AlunosStats({
    required this.total,
    required this.totalAtivos,
    required this.totalInadimplentes,
    required this.totalRiscoAlto,
    required this.totalConvites,
    this.totalContatoHoje = 0,
    this.totalInativos,
  });

  factory AlunosStats.fromJson(Map<String, dynamic> json) => AlunosStats(
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalAtivos: (json['totalAtivos'] as num?)?.toInt() ?? 0,
    totalInadimplentes: (json['totalInadimplentes'] as num?)?.toInt() ?? 0,
    totalRiscoAlto: (json['totalRiscoAlto'] as num?)?.toInt() ?? 0,
    totalConvites: (json['totalConvites'] as num?)?.toInt() ?? 0,
    totalContatoHoje: (json['totalContatoHoje'] as num?)?.toInt() ?? 0,
    totalInativos: (json['totalInativos'] as num?)?.toInt(),
  );
}

/// Sinais de evolução a partir de check-ins concluídos (backend).
class EvolucaoInteligente {
  final String sinal;
  final String resumo;
  final String? ultimoPrLabel;
  final double? ultimoPrCargaKg;
  final String? ultimoPrExercicio;
  final double volumeSemanal;
  final double volumeMensal;
  final int? tendenciaVolumePct;
  final String proximaAcao;
  final bool sugerirCopiloto;
  final List<double> volumePorSemana;

  const EvolucaoInteligente({
    required this.sinal,
    required this.resumo,
    this.ultimoPrLabel,
    this.ultimoPrCargaKg,
    this.ultimoPrExercicio,
    required this.volumeSemanal,
    required this.volumeMensal,
    this.tendenciaVolumePct,
    required this.proximaAcao,
    required this.sugerirCopiloto,
    this.volumePorSemana = const [],
  });

  factory EvolucaoInteligente.fromJson(Map<String, dynamic> json) =>
      EvolucaoInteligente(
        sinal: json['sinal'] as String? ?? 'SEM_DADOS',
        resumo: json['resumo'] as String? ?? '',
        ultimoPrLabel: json['ultimoPrLabel'] as String?,
        ultimoPrCargaKg: (json['ultimoPrCargaKg'] as num?)?.toDouble(),
        ultimoPrExercicio: json['ultimoPrExercicio'] as String?,
        volumeSemanal: (json['volumeSemanal'] as num?)?.toDouble() ?? 0,
        volumeMensal: (json['volumeMensal'] as num?)?.toDouble() ?? 0,
        tendenciaVolumePct: (json['tendenciaVolumePct'] as num?)?.toInt(),
        proximaAcao: json['proximaAcao'] as String? ?? '',
        sugerirCopiloto: json['sugerirCopiloto'] as bool? ?? false,
        volumePorSemana:
            (json['volumePorSemana'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
      );
}

class Timeline360Event {
  final String tipo;
  final String titulo;
  final String corpo;
  final String meta;
  final String ocorridoEm;
  final String deepLink;
  final String prioridade;

  const Timeline360Event({
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.meta,
    required this.ocorridoEm,
    required this.deepLink,
    required this.prioridade,
  });

  factory Timeline360Event.fromJson(Map<String, dynamic> json) =>
      Timeline360Event(
        tipo: json['tipo'] as String? ?? '',
        titulo: json['titulo'] as String? ?? '',
        corpo: json['corpo'] as String? ?? '',
        meta: json['meta'] as String? ?? '',
        ocorridoEm: json['ocorridoEm'] as String? ?? '',
        deepLink: json['deepLink'] as String? ?? '',
        prioridade: json['prioridade'] as String? ?? 'P2',
      );
}

class ProximaAcaoResumo {
  final String acao;
  final String motivo;
  final String fonte;
  final String prioridade;
  final String? fonteLabel;
  final String? tipoAcao;
  final String? mensagemSugerida;
  final String? stickyLabel;
  final String? stickyLabelCompact;
  final String? ctaLabel;
  final bool? wearableRelevant;

  const ProximaAcaoResumo({
    required this.acao,
    required this.motivo,
    required this.fonte,
    required this.prioridade,
    this.fonteLabel,
    this.tipoAcao,
    this.mensagemSugerida,
    this.stickyLabel,
    this.stickyLabelCompact,
    this.ctaLabel,
    this.wearableRelevant,
  });

  factory ProximaAcaoResumo.fromJson(Map<String, dynamic> json) =>
      ProximaAcaoResumo(
        acao: json['acao'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        fonte: json['fonte'] as String? ?? 'PADRAO',
        prioridade: json['prioridade'] as String? ?? 'P2',
        fonteLabel: json['fonteLabel'] as String?,
        tipoAcao: json['tipoAcao'] as String?,
        mensagemSugerida: json['mensagemSugerida'] as String?,
        stickyLabel: json['stickyLabel'] as String?,
        stickyLabelCompact: json['stickyLabelCompact'] as String?,
        ctaLabel: json['ctaLabel'] as String?,
        wearableRelevant: json['wearableRelevant'] as bool?,
      );
}

class AderenciaDia {
  final String data;
  final String labelDia;
  final int checkins;

  /// TREINOU · FALTOU · SEM_PLANO · HOJE (null em backend antigo).
  final String? status;

  const AderenciaDia({
    this.data = '',
    this.labelDia = '',
    this.checkins = 0,
    this.status,
  });

  factory AderenciaDia.fromJson(Map<String, dynamic> json) => AderenciaDia(
    // Contrato novo: dia/weekday · legado: data/labelDia.
    data: json['data'] as String? ?? json['dia'] as String? ?? '',
    labelDia: json['labelDia'] as String? ?? json['weekday'] as String? ?? '',
    checkins: (json['checkins'] as num?)?.toInt() ?? 0,
    status: (json['status'] as String?)?.trim().toUpperCase(),
  );

  Map<String, dynamic> toMap() => {
    'data': data,
    'labelDia': labelDia,
    'checkins': checkins,
    if (status != null) 'status': status,
  };
}

class AderenciaSemanalBundle {
  final List<AderenciaDia> dias;
  final int totalSemana;
  final int streakAtual;
  final int diasComCheckin;
  final String resumo;

  const AderenciaSemanalBundle({
    this.dias = const [],
    this.totalSemana = 0,
    this.streakAtual = 0,
    this.diasComCheckin = 0,
    this.resumo = '',
  });

  List<Map<String, dynamic>> get diasMaps =>
      dias.map((d) => d.toMap()).toList(growable: false);

  factory AderenciaSemanalBundle.fromJson(
    Map<String, dynamic> json,
  ) => AderenciaSemanalBundle(
    dias:
        (json['dias'] as List<dynamic>? ?? const [])
            .map(
              (e) => AderenciaDia.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
    totalSemana: (json['totalSemana'] as num?)?.toInt() ?? 0,
    streakAtual: (json['streakAtual'] as num?)?.toInt() ?? 0,
    diasComCheckin: (json['diasComCheckin'] as num?)?.toInt() ?? 0,
    resumo: json['resumo'] as String? ?? '',
  );

  factory AderenciaSemanalBundle.fromLegacyList(
    List<dynamic> raw,
  ) => AderenciaSemanalBundle(
    dias:
        raw
            .map(
              (e) => AderenciaDia.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
  );

  static AderenciaSemanalBundle parse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return AderenciaSemanalBundle.fromJson(raw);
    }
    if (raw is List) {
      return AderenciaSemanalBundle.fromLegacyList(raw);
    }
    return const AderenciaSemanalBundle();
  }
}

class RiscoResumo {
  const RiscoResumo({
    required this.score,
    required this.motivos,
    required this.nivel,
    required this.emRisco,
  });

  final int score;
  final List<String> motivos;
  final String nivel;
  final bool emRisco;

  factory RiscoResumo.fromJson(Map<String, dynamic> json) => RiscoResumo(
    score: (json['score'] as num?)?.toInt() ?? 0,
    motivos:
        (json['motivos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
    nivel: (json['nivel'] as String?) ?? 'BAIXO',
    emRisco:
        json['emRisco'] as bool? ?? ((json['score'] as num?)?.toInt() ?? 0) > 0,
  );
}

class Timeline360Page {
  const Timeline360Page({
    required this.events,
    required this.hasMore,
    this.nextOffset,
    this.totalCount = 0,
  });

  final List<Timeline360Event> events;
  final bool hasMore;
  final int? nextOffset;
  final int totalCount;

  factory Timeline360Page.fromJson(Map<String, dynamic> json) =>
      Timeline360Page(
        events:
            (json['events'] as List<dynamic>? ?? const [])
                .map(
                  (e) => Timeline360Event.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
        hasMore: json['hasMore'] as bool? ?? false,
        nextOffset: (json['nextOffset'] as num?)?.toInt(),
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      );
}

class OperacaoUiHints {
  final bool contactPriority;
  final bool defaultFocusMode;
  final bool compactFollowUp;

  const OperacaoUiHints({
    required this.contactPriority,
    required this.defaultFocusMode,
    required this.compactFollowUp,
  });

  factory OperacaoUiHints.fromJson(Map<String, dynamic> json) =>
      OperacaoUiHints(
        contactPriority: json['contactPriority'] as bool? ?? false,
        defaultFocusMode: json['defaultFocusMode'] as bool? ?? false,
        compactFollowUp: json['compactFollowUp'] as bool? ?? false,
      );
}

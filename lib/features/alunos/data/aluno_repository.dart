import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../exercicios/data/enums.dart';

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
  });

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
    equipamentosDisponiveis:
        parseEnumCsv(
          Equipamento.values,
          json['equipamentosDisponiveis'] ??
              json['equipamentosDisponiveisCsv'] ??
              json['equipamentos_disponiveis'],
        ).toSet(),
  );
}

class AlunoAutonomiaEvento {
  final int id;
  final String taskId;
  final String taskTitle;
  final String action;
  final String? route;
  final String? priority;
  final bool done;
  final int? profileCompletion;
  final DateTime? criadoEm;

  const AlunoAutonomiaEvento({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.action,
    this.route,
    this.priority,
    this.done = false,
    this.profileCompletion,
    this.criadoEm,
  });

  factory AlunoAutonomiaEvento.fromJson(Map<String, dynamic> json) =>
      AlunoAutonomiaEvento(
        id: (json['id'] as num).toInt(),
        taskId: json['taskId'] as String? ?? '',
        taskTitle: json['taskTitle'] as String? ?? 'Tarefa do aluno',
        action: json['action'] as String? ?? '',
        route: json['route'] as String?,
        priority: json['priority'] as String?,
        done: json['done'] as bool? ?? false,
        profileCompletion: (json['profileCompletion'] as num?)?.toInt(),
        criadoEm:
            json['criadoEm'] == null
                ? null
                : DateTime.tryParse(json['criadoEm'].toString()),
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

class AlunoRepository {
  final Dio _dio;

  AlunoRepository(ApiClient client) : _dio = client.dio;

  Future<List<Aluno>> listar() async {
    final response = await _dio.get('/api/alunos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Aluno.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Aluno> buscar(int id) async {
    final response = await _dio.get('/api/alunos/$id');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> criar({
    required String nome,
    required String email,
    String? objetivo,
    String? whatsapp,
    String? genero,
    String? tipoConsultoria,
  }) async {
    final response = await _dio.post(
      '/api/alunos',
      data: {
        'nome': nome,
        'email': email,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (genero != null && genero.isNotEmpty) 'genero': genero,
        if (tipoConsultoria != null && tipoConsultoria.isNotEmpty)
          'tipoConsultoria': tipoConsultoria,
      },
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> atualizarStatusFinanceiro(int alunoId, String status) async {
    await _dio.patch(
      '/api/alunos/$alunoId/status-financeiro',
      data: {'status': status},
    );
  }

  Future<Aluno> atualizarAluno(int id, Map<String, dynamic> data) async {
    final r = await _dio.put('/api/alunos/$id', data: data);
    return Aluno.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluirAluno(int id) async {
    await _dio.delete('/api/alunos/$id');
  }

  Future<void> atualizarEquipamentos(
    int alunoId,
    Set<Equipamento> equipamentos,
  ) async {
    await _dio.patch(
      '/api/alunos/$alunoId/equipamentos',
      data: {'equipamentos': equipamentos.map((e) => e.backendName).toList()},
    );
  }

  Future<List<Map<String, dynamic>>> aderenciaSemanal(int id) async {
    final response = await _dio.get('/api/alunos/$id/aderencia-semanal');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<AlunoAutonomiaEvento>> listarAutonomiaEventos(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/autonomia/eventos');
    return (response.data as List<dynamic>)
        .map((e) => AlunoAutonomiaEvento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AlunoAutonomiaResumo> buscarAutonomiaResumo(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/autonomia/resumo');
    return AlunoAutonomiaResumo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EvolucaoInteligente> buscarEvolucaoInteligente(int alunoId) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/evolucao-inteligente',
    );
    return EvolucaoInteligente.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Timeline360Event>> buscarTimeline360(
    int alunoId, {
    int limit = 40,
  }) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/timeline-360',
      queryParameters: {'limit': limit},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Timeline360Event.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> gerarSenhaProvisoria(int id) async {
    final response = await _dio.post('/api/alunos/$id/gerar-senha-provisoria');
    return response.data['senhaProvisoria'] as String;
  }

  Future<Aluno> me() async {
    final response = await _dio.get('/api/aluno/me');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> atualizarMe(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/aluno/me', data: data);
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> registrarEventoAutonomia({
    required String taskId,
    required String taskTitle,
    required String action,
    String? route,
    String? priority,
    bool? done,
    int? profileCompletion,
  }) async {
    await _dio.post(
      '/api/aluno/autonomia/eventos',
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'action': action,
        if (route != null) 'route': route,
        if (priority != null) 'priority': priority,
        if (done != null) 'done': done,
        if (profileCompletion != null) 'profileCompletion': profileCompletion,
      },
    );
  }

  // Telefone getter helper (nao esta no modelo ainda)
  String? getTelefone(Aluno aluno) => null;
}

import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AdminStats {
  final int totalPersonais;
  final int totalAlunos;
  final int admins;
  AdminStats({required this.totalPersonais, required this.totalAlunos, required this.admins});
  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    totalPersonais: j['totalPersonais'] as int,
    totalAlunos: j['totalAlunos'] as int,
    admins: j['admins'] as int,
  );
}

class AdminPersonal {
  final int id;
  final String nome;
  final String email;
  final String plano;
  final bool isAdmin;
  final String criadoEm;
  AdminPersonal({required this.id, required this.nome, required this.email,
    required this.plano, required this.isAdmin, required this.criadoEm});
  factory AdminPersonal.fromJson(Map<String, dynamic> j) => AdminPersonal(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String,
    email: j['email'] as String,
    plano: j['plano'] as String? ?? '—',
    isAdmin: j['isAdmin'] as bool? ?? false,
    criadoEm: j['criadoEm'] as String? ?? '—',
  );
}

class SuporteTicket {
  final int id;
  final int? personalId;
  final String? personalNome;
  final String titulo;
  final String descricao;
  final String severidade;
  final String status;
  final String? classeAfetada;
  final String? sugestaoIa;
  final String? respostaAdmin;
  final String criadoEm;

  SuporteTicket({
    required this.id,
    this.personalId,
    this.personalNome,
    required this.titulo,
    required this.descricao,
    required this.severidade,
    required this.status,
    this.classeAfetada,
    this.sugestaoIa,
    this.respostaAdmin,
    required this.criadoEm,
  });

  factory SuporteTicket.fromJson(Map<String, dynamic> j) => SuporteTicket(
    id: (j['id'] as num).toInt(),
    personalId: j['personalId'] != null ? (j['personalId'] as num).toInt() : null,
    personalNome: j['personalNome'] as String?,
    titulo: j['titulo'] as String? ?? '—',
    descricao: j['descricao'] as String? ?? '—',
    severidade: j['severidade'] as String? ?? 'BAIXA',
    status: j['status'] as String? ?? 'ABERTO',
    classeAfetada: j['classeAfetada'] as String?,
    sugestaoIa: j['sugestaoIa'] as String?,
    respostaAdmin: j['respostaAdmin'] as String?,
    criadoEm: j['criadoEm'] as String? ?? '—',
  );
}

class PersonalRisco {
  final int id;
  final String nome;
  final String email;
  final String plano;
  final int totalAlunos;
  final int alunosInadimplentes;
  final int checkInsUltimos30Dias;

  PersonalRisco({
    required this.id,
    required this.nome,
    required this.email,
    required this.plano,
    required this.totalAlunos,
    required this.alunosInadimplentes,
    required this.checkInsUltimos30Dias,
  });

  factory PersonalRisco.fromJson(Map<String, dynamic> j) => PersonalRisco(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String? ?? '—',
    email: j['email'] as String? ?? '—',
    plano: j['plano'] as String? ?? '—',
    totalAlunos: (j['totalAlunos'] as num?)?.toInt() ?? 0,
    alunosInadimplentes: (j['alunosInadimplentes'] as num?)?.toInt() ?? 0,
    checkInsUltimos30Dias: (j['checkInsUltimos30Dias'] as num?)?.toInt() ?? 0,
  );
}

class AdminMonitor {
  final int ticketsAbertos;
  final int ticketsCriticos;
  final List<SuporteTicket> ultimosTickets;
  final List<PersonalRisco> personaisEmRisco;
  final int totalInadimplentes;

  AdminMonitor({
    required this.ticketsAbertos,
    required this.ticketsCriticos,
    required this.ultimosTickets,
    required this.personaisEmRisco,
    required this.totalInadimplentes,
  });

  factory AdminMonitor.fromJson(Map<String, dynamic> j) => AdminMonitor(
    ticketsAbertos: (j['ticketsAbertos'] as num?)?.toInt() ?? 0,
    ticketsCriticos: (j['ticketsCriticos'] as num?)?.toInt() ?? 0,
    ultimosTickets: (j['ultimosTickets'] as List<dynamic>?)
        ?.map((e) => SuporteTicket.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    personaisEmRisco: (j['personaisEmRisco'] as List<dynamic>?)
        ?.map((e) => PersonalRisco.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    totalInadimplentes: (j['totalInadimplentes'] as num?)?.toInt() ?? 0,
  );
}

class AdminRepository {
  final Dio _dio;
  AdminRepository(ApiClient c) : _dio = c.dio;

  Future<AdminStats> stats() async {
    final r = await _dio.get('/api/admin/stats');
    return AdminStats.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AdminPersonal>> listarPersonais() async {
    final r = await _dio.get('/api/admin/personais');
    return (r.data as List).map((e) => AdminPersonal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleAdmin(int id) async {
    await _dio.patch('/api/admin/personais/$id/toggle-admin');
  }

  Future<AdminMonitor> monitor() async {
    final r = await _dio.get('/api/admin/suporte/monitor');
    return AdminMonitor.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> resolverTicket(int id, {String? resposta}) async {
    await _dio.put('/api/admin/suporte/tickets/$id/resolver',
        data: {'respostaAdmin': resposta});
  }
}

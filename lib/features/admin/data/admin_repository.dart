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
}

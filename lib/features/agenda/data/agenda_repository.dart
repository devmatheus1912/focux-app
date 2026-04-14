import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Agendamento {
  final int id;
  final int alunoId;
  final String alunoNome;
  final DateTime inicio;
  final DateTime fim;
  final String? titulo;
  final String status;

  Agendamento({required this.id, required this.alunoId, required this.alunoNome,
    required this.inicio, required this.fim, this.titulo, required this.status});

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    inicio: DateTime.parse(j['inicio'] as String),
    fim: DateTime.parse(j['fim'] as String),
    titulo: j['titulo'] as String?,
    status: j['status'] as String,
  );
}

class AgendaRepository {
  final Dio _dio;
  AgendaRepository(ApiClient c) : _dio = c.dio;

  Future<List<Agendamento>> proximos() async {
    final r = await _dio.get('/api/agenda');
    return (r.data as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  Future<Agendamento> criar(int alunoId, DateTime inicio, DateTime fim, String? titulo) async {
    final r = await _dio.post('/api/agenda', data: {
      'alunoId': alunoId,
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
      if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
    });
    return Agendamento.fromJson(r.data);
  }

  Future<void> excluir(int id) => _dio.delete('/api/agenda/$id');
}

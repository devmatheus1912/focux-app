import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ExecucaoExercicio {
  final int id;
  final int treinoExercicioId;
  final String exercicioNome;
  final String? gifUrl;
  final int? series;
  final String? repeticoes;
  final int seriesFeitas;
  final bool concluido;

  ExecucaoExercicio({
    required this.id,
    required this.treinoExercicioId,
    required this.exercicioNome,
    this.gifUrl,
    this.series,
    this.repeticoes,
    required this.seriesFeitas,
    required this.concluido,
  });

  factory ExecucaoExercicio.fromJson(Map<String, dynamic> j) => ExecucaoExercicio(
        id: j['id'] as int,
        treinoExercicioId: j['treinoExercicioId'] as int,
        exercicioNome: j['exercicioNome'] as String,
        gifUrl: j['gifUrl'] as String?,
        series: j['series'] as int?,
        repeticoes: j['repeticoes'] as String?,
        seriesFeitas: j['seriesFeitas'] as int,
        concluido: j['concluido'] as bool,
      );

  ExecucaoExercicio copyWith({int? seriesFeitas, bool? concluido}) => ExecucaoExercicio(
        id: id,
        treinoExercicioId: treinoExercicioId,
        exercicioNome: exercicioNome,
        gifUrl: gifUrl,
        series: series,
        repeticoes: repeticoes,
        seriesFeitas: seriesFeitas ?? this.seriesFeitas,
        concluido: concluido ?? this.concluido,
      );
}

class ExecucaoTreino {
  final int? id;
  final int treinoId;
  final String treinoNome;
  final String status;
  final String? iniciadoEm;
  final String? concluidoEm;
  final List<ExecucaoExercicio> exercicios;

  ExecucaoTreino({
    this.id,
    required this.treinoId,
    required this.treinoNome,
    required this.status,
    this.iniciadoEm,
    this.concluidoEm,
    required this.exercicios,
  });

  factory ExecucaoTreino.fromJson(Map<String, dynamic> j) => ExecucaoTreino(
        id: j['id'] as int?,
        treinoId: j['treinoId'] as int,
        treinoNome: j['treinoNome'] as String,
        status: j['status'] as String,
        iniciadoEm: j['iniciadoEm'] as String?,
        concluidoEm: j['concluidoEm'] as String?,
        exercicios: (j['exercicios'] as List<dynamic>)
            .map((e) => ExecucaoExercicio.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CheckinRepository {
  final Dio _dio;

  CheckinRepository(ApiClient client) : _dio = client.dio;

  Future<List<ExecucaoTreino>> meusTreinos() async {
    final r = await _dio.get('/api/checkin/meus-treinos');
    return (r.data as List).map((e) => ExecucaoTreino.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExecucaoTreino> iniciar(int treinoId) async {
    final r = await _dio.post('/api/checkin/iniciar', data: {'treinoId': treinoId});
    return ExecucaoTreino.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ExecucaoExercicio> marcarExercicio(int execucaoId, int treinoExercicioId, int seriesFeitas) async {
    final r = await _dio.put(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId',
      data: {'seriesFeitas': seriesFeitas},
    );
    return ExecucaoExercicio.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ExecucaoTreino> concluir(int execucaoId) async {
    final r = await _dio.put('/api/checkin/$execucaoId/concluir');
    return ExecucaoTreino.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ExecucaoTreino>> historico() async {
    final r = await _dio.get('/api/checkin/historico');
    return (r.data as List).map((e) => ExecucaoTreino.fromJson(e as Map<String, dynamic>)).toList();
  }
}

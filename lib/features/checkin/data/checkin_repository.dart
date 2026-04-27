import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ExecucaoExercicio {
  final int id;
  final int treinoExercicioId;
  final String exercicioNome;
  final String? gifUrl;
  final int? series;
  final String? repeticoes;
  final double? cargaKg;
  final int? descansoSegundos;
  final String? observacoes;
  final int seriesFeitas;
  final bool concluido;
  final String? feedback;
  final int? rpe;
  final bool dor;
  final double? cargaAnteriorKg;
  final int? seriesFeitasAnterior;
  final String? feedbackAnterior;
  final int? rpeAnterior;
  final bool? dorAnterior;

  ExecucaoExercicio({
    required this.id,
    required this.treinoExercicioId,
    required this.exercicioNome,
    this.gifUrl,
    this.series,
    this.repeticoes,
    this.cargaKg,
    this.descansoSegundos,
    this.observacoes,
    required this.seriesFeitas,
    required this.concluido,
    this.feedback,
    this.rpe,
    this.dor = false,
    this.cargaAnteriorKg,
    this.seriesFeitasAnterior,
    this.feedbackAnterior,
    this.rpeAnterior,
    this.dorAnterior,
  });

  factory ExecucaoExercicio.fromJson(Map<String, dynamic> j) => ExecucaoExercicio(
        id: j['id'] as int,
        treinoExercicioId: j['treinoExercicioId'] as int,
        exercicioNome: j['exercicioNome'] as String,
        gifUrl: j['gifUrl'] as String?,
        series: j['series'] as int?,
        repeticoes: j['repeticoes'] as String?,
        cargaKg: _toDouble(j['cargaKg']),
        descansoSegundos: j['descansoSegundos'] as int?,
        observacoes: j['observacoes'] as String?,
        seriesFeitas: j['seriesFeitas'] as int,
        concluido: j['concluido'] as bool,
        feedback: j['feedback'] as String?,
        rpe: j['rpe'] as int?,
        dor: j['dor'] as bool? ?? false,
        cargaAnteriorKg: _toDouble(j['cargaAnteriorKg']),
        seriesFeitasAnterior: j['seriesFeitasAnterior'] as int?,
        feedbackAnterior: j['feedbackAnterior'] as String?,
        rpeAnterior: j['rpeAnterior'] as int?,
        dorAnterior: j['dorAnterior'] as bool?,
      );

  ExecucaoExercicio copyWith({
    int? seriesFeitas,
    bool? concluido,
    String? feedback,
    int? rpe,
    bool? dor,
  }) =>
      ExecucaoExercicio(
        id: id,
        treinoExercicioId: treinoExercicioId,
        exercicioNome: exercicioNome,
        gifUrl: gifUrl,
        series: series,
        repeticoes: repeticoes,
        cargaKg: cargaKg,
        descansoSegundos: descansoSegundos,
        observacoes: observacoes,
        seriesFeitas: seriesFeitas ?? this.seriesFeitas,
        concluido: concluido ?? this.concluido,
        feedback: feedback ?? this.feedback,
        rpe: rpe ?? this.rpe,
        dor: dor ?? this.dor,
        cargaAnteriorKg: cargaAnteriorKg,
        seriesFeitasAnterior: seriesFeitasAnterior,
        feedbackAnterior: feedbackAnterior,
        rpeAnterior: rpeAnterior,
        dorAnterior: dorAnterior,
      );
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
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

  Future<ExecucaoExercicio> marcarExercicio(
    int execucaoId,
    int treinoExercicioId,
    int seriesFeitas, {
    String? feedback,
    int? rpe,
    bool? dor,
  }) async {
    final r = await _dio.put(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId',
      data: {
        'seriesFeitas': seriesFeitas,
        if (feedback != null) 'feedback': feedback,
        if (rpe != null) 'rpe': rpe,
        if (dor != null) 'dor': dor,
      },
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

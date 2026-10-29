import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/ficha_modelo.dart';
import '../models/ficha_volume.dart';
import '../models/rotina_fila.dart';
import '../utils/semana_da_fila.dart';
import 'treino_repository.dart';

class FichaModeloRepository {
  FichaModeloRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<FichaModelo>> listar() async {
    final response = await _dio.get('/api/ficha-modelos');
    return (response.data as List? ?? const [])
        .whereType<Map>()
        .map((json) => FichaModelo.fromJson(Map<String, dynamic>.from(json)))
        .toList(growable: false);
  }

  Future<FichaModelo> buscar(int id) async {
    final response = await _dio.get('/api/ficha-modelos/$id');
    return FichaModelo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FichaVolume> volumeDoModelo(int id) async {
    final response = await _dio.get('/api/ficha-modelos/$id/volume');
    return FichaVolume.fromJson(response.data);
  }

  /// Salva a ficha atual de [alunoId] como modelo (copia as sessões).
  Future<FichaModelo> criarDaFicha({
    required String nome,
    required int alunoId,
  }) => _criar({'nome': nome, 'alunoId': alunoId});

  /// Cria um modelo com Treino A, B, C… vazios nos dias padrão.
  Future<FichaModelo> criarPorDias({
    required String nome,
    required int diasPorSemana,
  }) => _criar({'nome': nome, 'diasPorSemana': diasPorSemana});

  /// Cria um modelo já com a semana montada (dias, divisão, segue a sequência).
  Future<FichaModelo> criarPelaSemana({
    required String nome,
    required List<DiaDaSemana> dias,
  }) => _criar({'nome': nome, 'dias': semanaComoJson(dias)});

  /// Troca a semana do modelo (mesmo formato da ficha do aluno).
  Future<FichaModelo> gravarSemana(int id, List<DiaDaSemana> dias) async {
    final response = await _dio.put(
      '/api/ficha-modelos/$id/semana',
      data: {'dias': semanaComoJson(dias)},
    );
    return FichaModelo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FichaModelo> _criar(Map<String, Object> corpo) async {
    final response = await _dio.post('/api/ficha-modelos', data: corpo);
    return FichaModelo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FichaModelo> renomear(int id, String nome) async {
    final response = await _dio.put('/api/ficha-modelos/$id', data: {'nome': nome});
    return FichaModelo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> arquivar(int id) => _dio.delete('/api/ficha-modelos/$id');

  /// Aplica o modelo no aluno: o backend copia as sessões e troca a ficha.
  Future<RotinaFila> aplicar(
    int id,
    int alunoId, {
    bool manterCargas = true,
  }) async {
    final response = await _dio.post(
      '/api/ficha-modelos/$id/aplicar/$alunoId',
      queryParameters: {'manterCargas': manterCargas},
    );
    return RotinaFila.fromJson(response.data);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/friendly_error.dart';
import 'plano_sucesso_display.dart';
import 'plano_sucesso_model.dart';

class PlanoSucessoProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  PlanoSucesso? _plano;
  bool _isLoading = false;
  String? _erro;

  PlanoSucesso? get plano => _plano;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  Future<void> fetchPlano(int alunoId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
      _plano = PlanoSucesso.fromJson(res.data);
    } catch (e) {
      _plano = null;
      final notFound = e is DioException && e.response?.statusCode == 404;
      _erro = notFound ? null : friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> criarPlano({
    required int alunoId,
    required String objetivoPrincipal,
    required List<String> titulosMarcos,
  }) async {
    await _api.dio.post(
      '/api/planos-sucesso',
      data: {
        'alunoId': alunoId,
        'objetivoPrincipal': objetivoPrincipal,
        'titulosMarcos': titulosMarcos,
      },
    );
    final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
    _plano = PlanoSucesso.fromJson(res.data);
    _erro = null;
    notifyListeners();
  }

  Future<void> atingirMarco(int marcoId, {required int alunoId}) async {
    await _api.dio.patch('/api/planos-sucesso/marcos/$marcoId/atingir');
    final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
    _plano = PlanoSucesso.fromJson(res.data);
    _erro = null;
    notifyListeners();
  }

  Future<void> removerMarco(int marcoId, {required int alunoId}) async {
    await _api.dio.delete('/api/planos-sucesso/marcos/$marcoId');
    final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
    _plano = PlanoSucesso.fromJson(res.data);
    _erro = null;
    notifyListeners();
  }

  Future<void> revisarPlano({
    required int planoId,
    required int alunoId,
    required DateTime novaProximaRevisao,
  }) async {
    await _api.dio.patch(
      '/api/planos-sucesso/$planoId/revisar',
      data: {'novaProximaRevisao': planoSucessoRevisaoIso(novaProximaRevisao)},
    );
    final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
    _plano = PlanoSucesso.fromJson(res.data);
    _erro = null;
    notifyListeners();
  }

  Future<void> atualizarPlano({
    required int planoId,
    required int alunoId,
    required String objetivoPrincipal,
    required List<({int? id, String titulo})> marcos,
  }) async {
    await _api.dio.patch(
      '/api/planos-sucesso/$planoId',
      data: {
        'objetivoPrincipal': objetivoPrincipal,
        'marcos': [
          for (final m in marcos)
            {
              if (m.id != null) 'id': m.id,
              'titulo': m.titulo,
            },
        ],
      },
    );
    final res = await _api.dio.get('/api/planos-sucesso/aluno/$alunoId');
    _plano = PlanoSucesso.fromJson(res.data);
    _erro = null;
    notifyListeners();
  }
}

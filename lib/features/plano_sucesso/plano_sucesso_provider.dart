import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/friendly_error.dart';
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

  Future<void> atingirMarco(int marcoId) async {
    try {
      await _api.dio.patch('/api/planos-sucesso/marcos/$marcoId/atingir');
      if (_plano != null) {
        final index = _plano!.marcos.indexWhere((m) => m.id == marcoId);
        if (index != -1) {
          _plano!.marcos[index] = MarcoSucesso(
            id: marcoId,
            titulo: _plano!.marcos[index].titulo,
            atingido: true,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}

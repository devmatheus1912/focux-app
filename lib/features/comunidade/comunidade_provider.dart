import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';
import 'comunidade_model.dart';

class ComunidadeProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  List<GrupoComunidade> _grupos = [];
  bool _isLoading = false;

  List<GrupoComunidade> get grupos => _grupos;
  bool get isLoading => _isLoading;

  Future<void> fetchGrupos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/comunidade/grupos');
      _grupos = (res.data as List).map((g) => GrupoComunidade.fromJson(g)).toList();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> entrarGrupo(int grupoId) async {
    try {
      await _api.dio.post('/api/comunidade/grupos/$grupoId/entrar');
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

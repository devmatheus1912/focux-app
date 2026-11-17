import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vídeo de exercício sem gastar o plano do aluno (SPEC-checkin-offline 3.3).
///
/// - Vídeo visto fica no aparelho e toca do arquivo da segunda vez em diante.
/// - No dado móvel, com "Economizar dados móveis" ligado (padrão), o vídeo não
///   toca sozinho: a tela mostra a capa e "Ver vídeo".
/// - No Wi-Fi, [baixarParaDepois] guarda os vídeos do próximo treino.
abstract final class FxEconomiaDeDados {
  static const prefKey = 'economizar_dados_moveis';

  /// Até ~40 vídeos (≈ 300 MB nos vídeos curtos de demonstração); sai o mais antigo.
  static final cache = CacheManager(
    Config(
      'focuxVideosExercicio',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 40,
    ),
  );

  static Future<bool> ligada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> definir(bool ligada) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, ligada);
  }

  /// Wi-Fi ou cabo: rede que não gasta o plano.
  static Future<bool> redeSemCusto() async {
    try {
      final redes = await Connectivity().checkConnectivity();
      return redes.contains(ConnectivityResult.wifi) || redes.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  /// Pode tocar da rede sem o aluno pedir?
  static Future<bool> podeTocarSozinho() async => await redeSemCusto() || !await ligada();

  /// O arquivo do vídeo, se já está no aparelho.
  static Future<File?> noAparelho(String url) async {
    try {
      final info = await cache.getFileFromCache(url);
      return info?.file;
    } catch (_) {
      return null;
    }
  }

  /// Guarda o vídeo no aparelho em segundo plano (só no Wi-Fi).
  static Future<void> baixarParaDepois(Iterable<String> urls) async {
    if (!await redeSemCusto()) return;
    for (final url in urls) {
      if (url.isEmpty || await noAparelho(url) != null) continue;
      try {
        await cache.downloadFile(url);
      } catch (_) {
        // Sem sinal no meio do caminho: tenta de novo na próxima vez.
      }
    }
  }

  /// Logout e troca de conta: nada do aluno anterior fica no aparelho.
  static Future<void> limpar() async {
    try {
      await cache.emptyCache();
    } catch (_) {}
  }
}

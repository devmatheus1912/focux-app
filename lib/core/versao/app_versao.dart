import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// O que fazer com a versão instalada (SPEC-notificacoes, 20/11).
enum AtualizacaoNecessaria {
  /// Em dia (ou o servidor não exige nada).
  nenhuma,

  /// Abaixo da recomendada: folha dispensável, uma vez por versão.
  recomendada,

  /// Abaixo da mínima: o app não segue até atualizar.
  obrigatoria,
}

/// "1.2.6+242" vira [1, 2, 6]; lixo vira nulo.
List<int>? _partes(String? versao) {
  if (versao == null) return null;
  var v = versao.trim();
  final mais = v.indexOf('+');
  if (mais >= 0) v = v.substring(0, mais);
  if (!RegExp(r'^\d{1,4}(\.\d{1,4}){0,3}$').hasMatch(v)) return null;
  return v.split('.').map(int.parse).toList();
}

/// Compara por número ("1.2.10" > "1.2.9"). Inválida conta como 0.0.0.
int compararVersoes(String a, String b) {
  final pa = _partes(a) ?? const [0];
  final pb = _partes(b) ?? const [0];
  for (var i = 0; i < (pa.length > pb.length ? pa.length : pb.length); i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Mínima e recomendada vêm do servidor; nula ou inválida não exige nada.
AtualizacaoNecessaria decidirAtualizacao({
  required String atual,
  String? minima,
  String? recomendada,
}) {
  if (_partes(minima) != null && compararVersoes(atual, minima!) < 0) {
    return AtualizacaoNecessaria.obrigatoria;
  }
  if (_partes(recomendada) != null &&
      compararVersoes(atual, recomendada!) < 0) {
    return AtualizacaoNecessaria.recomendada;
  }
  return AtualizacaoNecessaria.nenhuma;
}

/// Versão instalada, lida uma vez na abertura. Vai em toda requisição
/// (`X-App-Version`, `X-App-Platform`) e decide o aviso de atualização.
abstract final class AppInfo {
  static String? versao;

  static String? get plataforma {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  static Future<void> carregar() async {
    if (versao != null) return;
    try {
      versao = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Sem versão não há cabeçalho nem aviso; o app segue igual.
    }
  }

  /// Cabeçalhos de toda requisição; vazio enquanto a versão não foi lida.
  static Map<String, String> get cabecalhos {
    final v = versao;
    final p = plataforma;
    if (v == null || p == null) return const {};
    return {'X-App-Version': v, 'X-App-Platform': p};
  }
}

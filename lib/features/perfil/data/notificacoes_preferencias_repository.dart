import 'package:dio/dio.dart';

/// Uma escolha da tela Perfil > Notificações (tipo do servidor).
class PreferenciaDeNotificacao {
  const PreferenciaDeNotificacao({
    required this.tipo,
    required this.rotulo,
    required this.descricao,
    required this.ligado,
  });

  final String tipo;
  final String rotulo;
  final String descricao;
  final bool ligado;

  /// Canal do Android do mesmo tipo (o push manda `channel_id` igual).
  String get canal => tipo.toLowerCase();

  PreferenciaDeNotificacao comLigado(bool v) => PreferenciaDeNotificacao(
    tipo: tipo,
    rotulo: rotulo,
    descricao: descricao,
    ligado: v,
  );

  factory PreferenciaDeNotificacao.fromJson(Map<String, dynamic> j) =>
      PreferenciaDeNotificacao(
        tipo: j['tipo'] as String,
        rotulo: j['rotulo'] as String? ?? j['tipo'] as String,
        descricao: j['descricao'] as String? ?? '',
        ligado: j['ligado'] as bool? ?? true,
      );
}

/// Resultado do "Enviar notificação de teste".
enum ResultadoDoTeste { enviado, semAparelho, falhou }

ResultadoDoTeste resultadoDoTeste(String? bruto) => switch (bruto) {
  'ENVIADO' => ResultadoDoTeste.enviado,
  'SEM_TOKEN' || 'SILENCIADO' => ResultadoDoTeste.semAparelho,
  _ => ResultadoDoTeste.falhou,
};

String textoDoTeste(ResultadoDoTeste r) => switch (r) {
  ResultadoDoTeste.enviado => 'Enviada. Deve chegar em alguns segundos.',
  ResultadoDoTeste.semAparelho =>
    'Seu aparelho não tem notificações ativas. Ative e tente de novo.',
  ResultadoDoTeste.falhou => 'Falhou. Tente de novo.',
};

class NotificacoesPreferenciasRepository {
  NotificacoesPreferenciasRepository(this._dio);

  final Dio _dio;

  Future<List<PreferenciaDeNotificacao>> listar() async {
    final r = await _dio.get('/api/notificacoes/preferencias');
    return _itens(r.data);
  }

  Future<List<PreferenciaDeNotificacao>> salvar(
    PreferenciaDeNotificacao item,
  ) async {
    final r = await _dio.put(
      '/api/notificacoes/preferencias',
      data: {
        'itens': [
          {'tipo': item.tipo, 'ligado': item.ligado},
        ],
      },
    );
    return _itens(r.data);
  }

  Future<ResultadoDoTeste> testar() async {
    final r = await _dio.post('/api/notificacoes/teste');
    return resultadoDoTeste(
      (r.data as Map<String, dynamic>)['resultado'] as String?,
    );
  }

  static List<PreferenciaDeNotificacao> _itens(Object? data) =>
      ((data as Map<String, dynamic>)['itens'] as List)
          .cast<Map<String, dynamic>>()
          .map(PreferenciaDeNotificacao.fromJson)
          .toList();
}

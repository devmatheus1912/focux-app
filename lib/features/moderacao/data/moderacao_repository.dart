import '../../../core/api/api_client.dart';
import '../../../core/api/offline_queued_ack.dart';

enum DenunciaTipo {
  feedPost('FEED_POST'),
  feedComentario('FEED_COMENTARIO'),
  chatMensagem('CHAT_MENSAGEM'),
  iaResposta('IA_RESPOSTA'),
  comunidadePost('COMUNIDADE_POST');

  const DenunciaTipo(this.api);
  final String api;
}

enum DenunciaMotivo {
  spam('SPAM'),
  ofensivo('OFENSIVO'),
  assedio('ASSEDIO'),
  inadequado('INADEQUADO'),
  outro('OUTRO');

  const DenunciaMotivo(this.api);
  final String api;
}

class ModeracaoRepository {
  ModeracaoRepository(this._client);

  final ApiClient _client;

  static const detalheMax = 500;
  static const conteudoMax = 2000;

  Future<void> denunciar({
    required DenunciaTipo tipo,
    required DenunciaMotivo motivo,
    String? alvoId,
    String? detalhe,
    String? conteudo,
  }) async {
    final d = detalhe?.trim();
    final c = conteudo?.trim();
    throwIfQueuedOffline(
      await _client.dio.post(
        '/api/moderacao/denuncias',
        data: {
          'tipo': tipo.api,
          'alvoId': alvoId,
          'motivo': motivo.api,
          'detalhe': d == null || d.isEmpty ? null : _cut(d, detalheMax),
          'conteudo': c == null || c.isEmpty ? null : _cut(c, conteudoMax),
        },
      ),
    );
  }

  static String _cut(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}

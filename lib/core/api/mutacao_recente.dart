/// Conta escritas aceitas pelo servidor. Quem mostra dado agregado (Hoje, Alunos,
/// perfil do aluno) compara a geração ao voltar e busca de novo se mudou: assim
/// nenhuma tela precisa saber quem depende do que ela salvou.
abstract final class MutacaoRecente {
  static int _geracao = 0;

  static int get geracao => _geracao;

  /// Não muda dado que aparece em tela: login, eventos e registro de aparelho.
  static final _ignorar = RegExp(
    r'/api/(auth|analytics|product-events|eventos|fcm|telemetria)(/|$)',
  );

  static bool conta({required String metodo, required String caminho}) {
    if (metodo.toUpperCase() == 'GET' || metodo.toUpperCase() == 'HEAD') {
      return false;
    }
    return !_ignorar.hasMatch(caminho.split('?').first);
  }

  static void registrar({required String metodo, required String caminho}) {
    if (conta(metodo: metodo, caminho: caminho)) _geracao++;
  }
}

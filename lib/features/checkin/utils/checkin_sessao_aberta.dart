import '../../../core/api/api_error.dart';

/// 409 `CHECKIN_SESSAO_ABERTA`: outra ficha já está em execução.
class CheckinSessaoAberta {
  const CheckinSessaoAberta({this.execucaoId, this.treinoId, this.treinoNome});

  static const codigo = 'CHECKIN_SESSAO_ABERTA';

  final int? execucaoId;
  final int? treinoId;
  final String? treinoNome;

  /// `null` quando o erro não é a sessão aberta.
  static CheckinSessaoAberta? fromError(Object error) {
    final api = ApiError.from(error);
    if (api == null) return null;
    final byCode = api.codigo == codigo;
    final text = (api.mensagem ?? '').toLowerCase();
    final byText =
        !api.hasCodigo &&
        (text.contains('treino em aberto') || text.contains('descarte antes'));
    if (!byCode && !byText) return null;
    final nome = api.detalhes['treinoNome']?.trim();
    return CheckinSessaoAberta(
      execucaoId: int.tryParse(api.detalhes['execucaoId'] ?? ''),
      treinoId: int.tryParse(api.detalhes['treinoId'] ?? ''),
      treinoNome: nome == null || nome.isEmpty ? null : nome,
    );
  }

  String get mensagem {
    final nome = treinoNome;
    return nome == null
        ? 'Uma sessão ainda está aberta. Continue de onde parou ou descarte para começar este treino.'
        : '“$nome” ainda está aberto. Continue de onde parou ou descarte para começar este treino.';
  }
}

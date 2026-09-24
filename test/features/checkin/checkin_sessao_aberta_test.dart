import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_sessao_aberta.dart';

DioException _conflict(Map<String, dynamic> body) {
  final req = RequestOptions(path: '/api/checkin/iniciar');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: 409, data: body),
  );
}

void main() {
  test('lê ids da sessão aberta pelo código', () {
    final s = CheckinSessaoAberta.fromError(
      _conflict({
        'erro': 'Você tem um treino em aberto.',
        'codigo': 'CHECKIN_SESSAO_ABERTA',
        'detalhes': {'execucaoId': '9', 'treinoId': '4', 'treinoNome': 'Peito'},
      }),
    );
    expect(s, isNotNull);
    expect(s!.execucaoId, 9);
    expect(s.treinoId, 4);
    expect(s.mensagem, contains('Peito'));
  });

  test('backend antigo sem código cai no texto', () {
    final s = CheckinSessaoAberta.fromError(
      _conflict({'erro': 'Você tem um treino em aberto. Retome ou descarte antes.'}),
    );
    expect(s, isNotNull);
    expect(s!.treinoId, isNull);
  });

  test('outro erro não vira sessão aberta', () {
    expect(
      CheckinSessaoAberta.fromError(
        _conflict({'erro': 'Pagamento em atraso', 'codigo': 'OUTRO'}),
      ),
      isNull,
    );
    expect(CheckinSessaoAberta.fromError(Exception('x')), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

void main() {
  test('VencimentoItem aceita campos nulos', () {
    final item = VencimentoItem.fromJson({
      'mensalidadeId': 7,
      'alunoId': null,
      'alunoNome': null,
      'valor': null,
      'mesReferencia': null,
      'vencimento': null,
      'status': null,
    });
    expect(item.mensalidadeId, 7);
    expect(item.alunoNome, '');
    expect(item.mesReferencia, '');
    expect(item.status, '');
    expect(item.vencimento, isNull);
  });

  test('TopAlunoItem e EvolucaoMensalItem aceitam campos nulos', () {
    final top = TopAlunoItem.fromJson({
      'alunoId': null,
      'alunoNome': null,
      'totalPago': null,
    });
    expect(top.alunoId, 0);
    expect(top.alunoNome, '');

    final mes = EvolucaoMensalItem.fromJson({'mes': null, 'recebido': null});
    expect(mes.mes, '');
  });
}

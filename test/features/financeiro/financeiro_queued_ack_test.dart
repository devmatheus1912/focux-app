import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

void main() {
  final queued = <String, dynamic>{
    'status': 'queued',
    'message': 'Offline. Sincronizará quando houver rede.',
  };

  test('Mensalidade.fromJson rejeita envelope 202 queued', () {
    expect(() => Mensalidade.fromJson(queued), throwsA(isA<FormatException>()));
  });

  test('PixData.fromJson rejeita envelope 202 queued', () {
    expect(() => PixData.fromJson(queued), throwsA(isA<FormatException>()));
  });

  test('Mensalidade.fromJson aceita fatura real', () {
    final m = Mensalidade.fromJson({
      'id': 9,
      'alunoId': 3,
      'alunoNome': 'Ana',
      'valor': '120.00',
      'mesReferencia': '2026-09',
      'status': 'ABERTO',
    });
    expect(m.id, 9);
    expect(m.status, 'ABERTO');
  });
}

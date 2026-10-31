import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

void main() {




  test('data e nome do PDF', () {
    final d = DateTime(2026, 9, 3, 7, 5);
    expect(progressaoGeradoLabel(d), 'Gerado em 03/09/2026 07:05');
    expect(progressaoSlug('  João da Conceição  '), 'joao-da-conceicao');
    expect(progressaoSlug('!!!'), 'aluno');
    expect(
      progressaoPdfFileName('Ana Lú', d),
      'progressao_ana-lu_2026-09-03.pdf',
    );
  });
}

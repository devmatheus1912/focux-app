import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';

void main() {
  test('filtro da URL vira AlunoFiltro, inclusive inativos', () {
    expect(alunoFiltroFromQuery('inativos'), AlunoFiltro.inativos);
    expect(alunoFiltroFromQuery('risco'), AlunoFiltro.risco);
    expect(alunoFiltroFromQuery('qualquer'), AlunoFiltro.todos);
    expect(alunoFiltroFromQuery(null), AlunoFiltro.todos);
  });
}

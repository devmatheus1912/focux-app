import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';

void main() {
  test('appendAlunos merges pages preserving stats', () {
    final first = AlunosHomeBundle(
      alunos: [
        Aluno(id: 1, nome: 'Ana', email: 'a@test.com', status: 'ATIVO'),
      ],
      stats: const AlunosStats(
        total: 2,
        totalAtivos: 2,
        totalInadimplentes: 0,
        totalRiscoAlto: 0,
        totalConvites: 0,
      ),
      alertasConfig: AlertasConfiguracao(
        diasSemTreino: 7,
        aderenciaMinima: 50,
      ),
      page: const AlunosHomePageMeta(
        page: 0,
        size: 1,
        totalElements: 2,
        totalPages: 2,
        hasNext: true,
      ),
    );
    final second = AlunosHomeBundle(
      alunos: [
        Aluno(id: 2, nome: 'Bruno', email: 'b@test.com', status: 'ATIVO'),
      ],
      stats: const AlunosStats(
        total: 2,
        totalAtivos: 2,
        totalInadimplentes: 0,
        totalRiscoAlto: 0,
        totalConvites: 0,
      ),
      alertasConfig: AlertasConfiguracao(
        diasSemTreino: 7,
        aderenciaMinima: 50,
      ),
      page: const AlunosHomePageMeta(
        page: 1,
        size: 1,
        totalElements: 2,
        totalPages: 2,
        hasNext: false,
      ),
    );

    final merged = first.appendAlunos(second);
    expect(merged.alunos, hasLength(2));
    expect(merged.stats.total, 2);
    expect(merged.page.hasNext, isFalse);
  });
}

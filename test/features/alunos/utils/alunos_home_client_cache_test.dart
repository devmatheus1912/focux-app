import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';

void main() {
  setUp(AlunosHomeClientCache.clear);

  AlunosHomeBundle bundle() => AlunosHomeBundle(
    alunos: [
      Aluno(id: 1, nome: 'Ana', email: 'a***@test.com', status: 'ATIVO'),
    ],
    stats: const AlunosStats(
      total: 1,
      totalAtivos: 1,
      totalInadimplentes: 0,
      totalRiscoAlto: 0,
      totalConvites: 0,
      totalContatoHoje: 0,
    ),
    alertasConfig: AlertasConfiguracao(
      diasSemTreino: 7,
      aderenciaMinima: 50,
    ),
  );

  test('TTL 90s alinhado ao BE alunos-home', () {
    const query = AlunosHomeQuery();
    final t0 = DateTime(2026, 8, 17, 12);
    AlunosHomeClientCache.put(query, bundle(), now: t0);
    expect(
      AlunosHomeClientCache.getIfFresh(
        query,
        now: t0.add(const Duration(seconds: 89)),
      ),
      isNotNull,
    );
    expect(
      AlunosHomeClientCache.getIfFresh(
        query,
        now: t0.add(const Duration(seconds: 91)),
      ),
      isNull,
    );
  });

  test('cache miss when filtro changes', () {
    final t0 = DateTime(2026, 8, 17, 12);
    AlunosHomeClientCache.put(const AlunosHomeQuery(), bundle(), now: t0);
    expect(
      AlunosHomeClientCache.getIfFresh(
        const AlunosHomeQuery(filtro: AlunoFiltro.risco),
        now: t0,
      ),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';

void main() {
  setUp(AlunosHomeClientCache.clear);

  AlunosHomeBundle bundle({int total = 1}) => AlunosHomeBundle(
    alunos: [
      Aluno(id: 1, nome: 'Ana', email: 'a***@test.com', status: 'ATIVO'),
    ],
    stats: AlunosStats(
      total: total,
      totalAtivos: total,
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

  test('cache hit when filtro changes if entry exists', () {
    final t0 = DateTime(2026, 8, 17, 12);
    const riscoQuery = AlunosHomeQuery(filtro: AlunoFiltro.risco);
    AlunosHomeClientCache.put(riscoQuery, bundle(total: 2), now: t0);
    expect(
      AlunosHomeClientCache.getIfFresh(riscoQuery, now: t0),
      isNotNull,
    );
    expect(
      AlunosHomeClientCache.getIfFresh(const AlunosHomeQuery(), now: t0),
      isNull,
    );
  });
}

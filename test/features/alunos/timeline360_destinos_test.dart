import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_timeline_logic.dart';

/// Linha do tempo do 360: nunca abre tela do aluno; meta e medida juntas.
void main() {
  test('rota do app do aluno não abre para o personal', () {
    expect(resolveTimeline360DeepLinkForPersonal(link: '/chat/aluno', alunoId: 3), '');
    expect(resolveTimeline360DeepLinkForPersonal(link: '/aluno/perfil', alunoId: 3), '');
    expect(
      resolveTimeline360DeepLinkForPersonal(link: '/alunos/3/sessoes/9', alunoId: 3),
      '/alunos/3/sessoes/9',
    );
    expect(
      resolveTimeline360DeepLinkForPersonal(link: '/alunos/3/evolucao?data=2026-11-09', alunoId: 3),
      '/alunos/3/evolucao?data=2026-11-09',
    );
    expect(
      resolveTimeline360DeepLinkForPersonal(link: '/financeiro?alunoId=3', alunoId: 3),
      '/financeiro?alunoId=3',
    );
  });

  test('meta concluída e a medida do mesmo minuto viram uma linha', () {
    final t = DateTime(2026, 11, 9, 10, 40);
    final itens = [
      (kind: 'META', at: t),
      (kind: 'Medida', at: t.add(const Duration(seconds: 20))),
      (kind: 'Medida', at: DateTime(2026, 11, 9, 8, 59)),
    ];
    final juntos = juntarMetaEMedida(
      itens,
      kindOf: (i) => i.kind,
      atOf: (i) => i.at,
    );
    expect(juntos.map((i) => i.kind), ['META', 'Medida']);
    expect(juntos.last.at.hour, 8);
  });
}

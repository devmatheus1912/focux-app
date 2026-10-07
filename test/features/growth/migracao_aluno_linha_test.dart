import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/models/migracao_aluno_linha.dart';
import 'package:focux_app/features/growth/utils/migracao_linha_classifier.dart';

void main() {
  test('resultado de texto traz status e ignorados', () {
    final r = MigracaoTextoResultado.parse({
      'alunos': [
        {'nome': 'Ana', 'status': 'DUVIDOSO'},
        {'nome': 'Bruno Costa', 'email': 'bruno@example.com', 'status': 'VALIDO'},
      ],
      'ignorados': {
        'total': 7,
        'amostras': ['EMENTA: art. 10'],
      },
    })!;

    expect(r.alunos.first.status, MigracaoLinhaStatus.duvidoso);
    expect(r.alunos.first.selecionado, isFalse);
    expect(r.alunos.last.entraNoSalvamento, isTrue);
    expect(r.ignorados, 7);
    expect(r.amostrasIgnoradas, ['EMENTA: art. 10']);
  });

  test('toJson não manda status nem seleção', () {
    const linha = MigracaoAlunoLinha(
      nome: 'Ana',
      status: MigracaoLinhaStatus.duvidoso,
      selecionado: true,
    );
    expect(linha.toJson(), {'nome': 'Ana'});
  });

  test('preview do servidor mantém status por posição', () {
    final originais = [
      const MigracaoAlunoLinha(nome: 'Ana', status: MigracaoLinhaStatus.duvidoso),
      const MigracaoAlunoLinha(nome: 'Bruno Costa'),
    ];
    final preview = [
      const MigracaoAlunoLinha(nome: 'Ana'),
      const MigracaoAlunoLinha(nome: 'Bruno Costa', duplicado: true),
    ];

    final m = MigracaoAlunoLinha.mesclarPreview(originais, preview);

    expect(m.first.status, MigracaoLinhaStatus.duvidoso);
    expect(m.first.selecionado, isFalse);
    expect(m.last.duplicado, isTrue);
    expect(m.last.entraNoSalvamento, isFalse);
  });

  test('possível duplicado chega desmarcado, mas pode ser marcado', () {
    final m = MigracaoAlunoLinha.mesclarPreview(
      [const MigracaoAlunoLinha(nome: 'Ana Souza')],
      [
        MigracaoAlunoLinha.fromJson({
          'nome': 'Ana Souza',
          'possivelDuplicado': true,
        }),
      ],
    );

    expect(m.single.possivelDuplicado, isTrue);
    expect(m.single.entraNoSalvamento, isFalse);
    expect(m.single.copyWith(selecionado: true).entraNoSalvamento, isTrue);
  });

  test('possível duplicado fica desmarcado mesmo se o preview mudar de tamanho', () {
    final m = MigracaoAlunoLinha.mesclarPreview(
      [const MigracaoAlunoLinha(nome: 'Ana Souza')],
      [
        MigracaoAlunoLinha.fromJson({'nome': 'Ana Souza', 'possivelDuplicado': true}),
        MigracaoAlunoLinha.fromJson({'nome': 'Bruno Costa'}),
      ],
    );

    expect(m.first.entraNoSalvamento, isFalse);
    expect(m.last.entraNoSalvamento, isTrue);
  });
}

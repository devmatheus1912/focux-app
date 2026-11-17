import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_rotas_api.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/widgets/treinar_com_aluno_folha.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';

/// As 18 rotas da execução (9 do aluno, 9 do presencial) batem com o backend
/// (CheckinRotasContractTest) — SPEC-modo-presencial.
List<String> _tabela(CanalDoCheckin c) => [
  'POST ${c.iniciar()}',
  'POST ${c.serie(1, 2)}',
  'PUT ${c.exercicio(1, 2)}',
  'POST ${c.confirmarRestante(1, 2)}',
  'POST ${c.confirmarPlano()}',
  'PUT ${c.concluir(1)}',
  'PUT ${c.descartar(1)}',
  'GET ${c.detalhe(1)}',
  'GET ${c.evolucao(1)}',
];

void main() {
  test('canal do aluno e canal presencial: a mesma tabela, bases diferentes', () {
    expect(_tabela(const CanalDoAluno()), [
      'POST /api/checkin/iniciar',
      'POST /api/checkin/1/exercicio/2/series',
      'PUT /api/checkin/1/exercicio/2',
      'POST /api/checkin/1/exercicio/2/confirmar-restante',
      'POST /api/checkin/confirmar-plano',
      'PUT /api/checkin/1/concluir',
      'PUT /api/checkin/1/descartar',
      'GET /api/checkin/1',
      'GET /api/checkin/1/evolucao-sessao',
    ]);
    expect(_tabela(const CanalPresencial(7)), [
      'POST /api/checkin/personal/iniciar',
      'POST /api/checkin/personal/1/exercicio/2/series',
      'PUT /api/checkin/personal/1/exercicio/2',
      'POST /api/checkin/personal/1/exercicio/2/confirmar-restante',
      'POST /api/checkin/personal/confirmar-plano',
      'PUT /api/checkin/personal/1/concluir',
      'PUT /api/checkin/personal/1/descartar',
      'GET /api/checkin/personal/1',
      'GET /api/checkin/personal/1/evolucao-sessao',
    ]);
  });

  test('presencial diz de qual aluno no iniciar e no "Já fiz"; o aluno não', () {
    expect(const CanalPresencial(7).corpoDoTreino(3), {'treinoId': 3, 'alunoId': 7});
    expect(const CanalDoAluno().corpoDoTreino(3), {'treinoId': 3});
  });

  test('série da fila lembra o canal; item antigo (sem o campo) é do aluno', () {
    const presencial = CheckinSeriePendente(execucaoId: 1, treinoExercicioId: 2, numero: 1, presencialAlunoId: 7);
    final volta = CheckinSeriePendente.fromJson(presencial.toJson())!;
    expect(canalDe(volta.presencialAlunoId), const CanalPresencial(7));
    final antigo = CheckinSeriePendente.fromJson({'execucaoId': 1, 'treinoExercicioId': 2, 'numero': 1})!;
    expect(canalDe(antigo.presencialAlunoId), isA<CanalDoAluno>());
  });

  test('"Qual treino?": o próximo da fila vem marcado', () {
    final fila = RotinaFila.fromJson({
      'itens': [
        {'id': 1, 'tipo': 'TREINO', 'treinoId': 10, 'nome': 'A'},
        {'id': 2, 'tipo': 'TREINO', 'treinoId': 11, 'nome': 'B'},
        {'id': 3, 'tipo': 'TREINO', 'treinoId': 12, 'nome': 'C'},
      ],
      'ultimoTreinoId': 11,
    });
    expect(proximoTreinoDaFila(fila), 12);
    expect(treinarComAlunoPath(5, 12), '/alunos/5/treinar?treinoId=12');
  });

  test('contrato: caminho da execução só em checkin_rotas_api.dart', () {
    final permitidos = {
      'lib/features/checkin/data/checkin_rotas_api.dart',
      // Fora da execução: prévia, histórico e a home do personal.
      'lib/features/checkin/data/checkin_repository.dart',
    };
    final fora = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !permitidos.contains(f.path.replaceAll(r'\', '/')) &&
            f.readAsStringSync().contains("'/api/checkin"))
          f.path,
    ];
    expect(fora, isEmpty);
    final repo = File('lib/features/checkin/data/checkin_repository.dart').readAsStringSync();
    // Escrita da execução nunca com caminho literal: vem do canal.
    // (fora das 9 ações: só o envio da sessão feita sem internet, que é do aluno).
    final escritas = RegExp(r"_dio\.(post|put)\(\s*'(/api/checkin[^']*)'").allMatches(repo).map((m) => m.group(2)).toList();
    expect(escritas, ['/api/checkin/sessoes-offline']);
  });
}

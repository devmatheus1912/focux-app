import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/mutacao_recente.dart';
import 'package:focux_app/core/router/atualiza_ao_voltar_scope.dart';

void main() {
  test('escrita conta; leitura, login e evento não', () {
    expect(MutacaoRecente.conta(metodo: 'POST', caminho: '/api/alunos/1/medidas'), isTrue);
    expect(MutacaoRecente.conta(metodo: 'DELETE', caminho: '/api/feed/1'), isTrue);
    expect(MutacaoRecente.conta(metodo: 'GET', caminho: '/api/alunos'), isFalse);
    expect(MutacaoRecente.conta(metodo: 'POST', caminho: '/api/auth/login'), isFalse);
    expect(MutacaoRecente.conta(metodo: 'POST', caminho: '/api/fcm/token'), isFalse);
  });

  test('registrar sobe a geração só para escrita', () {
    final antes = MutacaoRecente.geracao;
    MutacaoRecente.registrar(metodo: 'GET', caminho: '/api/alunos');
    expect(MutacaoRecente.geracao, antes);
    MutacaoRecente.registrar(metodo: 'PUT', caminho: '/api/feed/1');
    expect(MutacaoRecente.geracao, antes + 1);
  });

  test('rotas que resumem dados', () {
    expect(telaResumoDaRota('/dashboard/personal')?.tela, TelaResumo.homePersonal);
    expect(telaResumoDaRota('/dashboard/aluno')?.tela, TelaResumo.homeAluno);
    expect(telaResumoDaRota('/alunos')?.tela, TelaResumo.alunos);
    expect(telaResumoDaRota('/alunos/42')?.alunoId, 42);
    expect(telaResumoDaRota('/alunos/42/evolucao'), isNull);
    expect(telaResumoDaRota('/treinos'), isNull);
  });

  test('atualiza se algo mudou ou passou da idade', () {
    final agora = DateTime(2026, 11, 1, 12);
    bool pede(int vista, Duration idade) => precisaAtualizar(
      geracaoVista: vista,
      geracaoAtual: 3,
      vistaEm: agora.subtract(idade),
      agora: agora,
    );
    expect(pede(2, Duration.zero), isTrue);
    expect(pede(3, const Duration(seconds: 10)), isFalse);
    expect(pede(3, const Duration(seconds: 31)), isTrue);
  });

  test('contrato: Home só atualiza pelo caminho que limpa o cache', () {
    final permitidos = {
      'dashboard_provider.dart',
      'session_cache_evictor.dart',
      'session_invalidator.dart',
    };
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (permitidos.any(f.path.endsWith)) continue;
      expect(
        f.readAsStringSync().contains('ref.invalidate(dashboardHomeProvider)'),
        isFalse,
        reason: f.path,
      );
    }
  });
}

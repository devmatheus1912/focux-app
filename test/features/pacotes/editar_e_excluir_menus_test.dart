import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/data/desafio_repository.dart';
import 'package:focux_app/features/desafios/utils/desafio_display.dart';
import 'package:focux_app/features/habitos/data/habito_repository.dart';
import 'package:focux_app/features/habitos/utils/habitos_display.dart';
import 'package:focux_app/features/leads/utils/lead_display.dart';
import 'package:focux_app/features/pacotes/data/pacote_repository.dart';
import 'package:focux_app/features/pacotes/utils/pacote_display.dart';

/// SPEC editar-e-excluir: o "⋯" mostra os itens certos por estado e o
/// Excluir só aparece onde o servidor diz que não há histórico.
void main() {
  test('desafio: editar e encerrar no ativo; excluir só sem contagem', () {
    expect(desafioMenuAcoes(ativo: true, podeExcluir: true), [
      'editar',
      'encerrar',
      'excluir',
    ]);
    expect(desafioMenuAcoes(ativo: true, podeExcluir: false), [
      'editar',
      'encerrar',
    ]);
    expect(desafioMenuAcoes(ativo: false, podeExcluir: false), isEmpty);
    final d = Desafio.fromJson({
      'id': 1,
      'titulo': 'Água',
      'tipo': 'HABITOS',
      'metaPontos': 12,
      'podeExcluir': true,
    });
    expect(d.podeExcluir, isTrue);
  });

  test('hábito: editar e desativar no ativo; reativar no desativado', () {
    expect(habitoMenuAcoes(ativo: true), ['editar', 'desativar']);
    expect(habitoMenuAcoes(ativo: false), ['reativar']);
    final home = HabitosHomeBundle.fromJson({
      'habitos': <dynamic>[],
      'compliance': <dynamic>[],
      'habitosDesativados': [
        {'id': 3, 'titulo': 'Dormir 8h', 'metaSemanal': 5, 'ativo': false},
      ],
    });
    expect(home.desativados.single.titulo, 'Dormir 8h');
    expect(habitoParaQuemTravado(null), contains('todos os alunos'));
  });

  test('plano: pausar no ativo, reativar no pausado, excluir sem vendas', () {
    expect(pacoteMenuAcoes(ativo: true, podeExcluir: false), [
      'destaque',
      'pausar',
    ]);
    expect(pacoteMenuAcoes(ativo: false, podeExcluir: true), [
      'reativar',
      'excluir',
    ]);
    final home = PacotesHomeBundle.fromJson({
      'content': <dynamic>[],
      'pausados': [
        {
          'id': 7,
          'titulo': 'Mensal',
          'valor': '150.00',
          'ativo': false,
          'podeExcluir': true,
        },
      ],
    });
    expect(home.pausados.single.podeExcluir, isTrue);
  });

  test('oferta: excluir só a nunca enviada', () {
    expect(ofertaMenuAcoes(ativo: true, enviadas: 0), [
      'enviar',
      'ativo',
      'excluir',
    ]);
    expect(ofertaMenuAcoes(ativo: true, enviadas: 2), ['enviar', 'ativo']);
  });

  test('interessado: quem virou aluno não tem excluir', () {
    expect(interessadoPodeExcluir(status: 'LEAD'), isTrue);
    expect(interessadoPodeExcluir(status: 'CONVERTIDO'), isFalse);
    expect(interessadoPodeExcluir(status: 'LEAD', alunoId: 9), isFalse);
    expect(interessadoExcluirTitulo('Thales Souza'), 'Excluir Thales?');
  });
}

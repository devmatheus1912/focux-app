import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/qualidade_operacional.dart';
import 'package:focux_app/features/dashboard/utils/qualidade_operacional_display.dart';

void main() {
  QualidadeOperacionalData data({
    double ticket = 300,
    double mercadoTicket = 250,
    int retencao = 80,
    int mercadoRetencao = 75,
    int score = 90,
  }) {
    return QualidadeOperacionalData(
      ticketPessoal: ticket,
      ticketMercado: mercadoTicket,
      retencaoPessoal: retencao,
      retencaoMercado: mercadoRetencao,
      score: score,
      recomendacao: 'ok',
    );
  }

  test('faixa do índice', () {
    expect(qualidadeScoreBand(80), QualidadeScoreBand.excellent);
    expect(qualidadeScoreLabel(80), 'Excelente');
    expect(qualidadeScoreBand(50), QualidadeScoreBand.good);
    expect(qualidadeScoreBand(49), QualidadeScoreBand.attention);
  });

  test('próxima ação prioriza retenção, depois ticket', () {
    expect(qualidadeNextAction(data(retencao: 60)).route, '/retencao');
    expect(
      qualidadeNextAction(data(ticket: 200, retencao: 80)).route,
      '/financeiro',
    );
    expect(
      qualidadeNextAction(data(ticket: 200, retencao: 80)).label,
      'Mensalidades',
    );
    expect(qualidadeNextAction(data()).route, '/alunos');
    expect(qualidadeNextAction(data()).shellTab, isTrue);
    expect(qualidadeComoCalculamos, contains('ticket'));
    expect(qualidadeComoCalculamos, contains('recorte'));
    expect(qualidadeComoCalculamos, contains('retenção'));
  });

  test('recomendação segue as métricas, não o texto cru do BE', () {
    expect(
      qualidadeRecomendacaoDisplay(data(ticket: 200, retencao: 80)),
      contains('precificação'),
    );
    expect(
      qualidadeRecomendacaoDisplay(data(retencao: 60)),
      contains('retenção'),
    );
    expect(
      qualidadeRecomendacaoDisplay(data()),
      'ok',
    );
  });
}

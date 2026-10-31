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

  test('base pequena avisa que o índice oscila', () {
    expect(qualidadeBasePequena(4), isTrue);
    expect(qualidadeBasePequena(5), isFalse);
    expect(qualidadeBasePequena(null), isFalse);
    expect(qualidadeComoCalculamos, contains('referência'));
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
      qualidadeRecomendacaoDisplay(data(ticket: 0, retencao: 80)),
      contains('Cadastre mensalidades'),
    );
    expect(
      qualidadeRecomendacaoDisplay(data()),
      'ok',
    );
  });

  test('ticket zero não compete com mercado', () {
    expect(qualidadeTicketUnavailable(0), isTrue);
    expect(qualidadeTicketValueLabel(0), 'Sem ticket');
    expect(
      qualidadeTicketHint(ticketPessoal: 0, ticketMercado: 250),
      'Indisponível · referência R\$ 250',
    );
    expect(qualidadeTicketValueLabel(300), 'R\$ 300');
    expect(
      qualidadeTicketHint(ticketPessoal: 300, ticketMercado: 250),
      'Acima da referência R\$ 250',
    );
    expect(
      qualidadeTicketHint(ticketPessoal: 200, ticketMercado: 250),
      'Referência R\$ 250',
    );
  });

  test('ticket compacto arredonda, não trunca', () {
    expect(qualidadeTicketValueLabel(149.9), 'R\$ 150');
    expect(qualidadeTicketValueLabel(149.49), 'R\$ 149');
  });
}

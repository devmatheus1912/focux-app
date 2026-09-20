import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/utils/oferta_upsell_display.dart';

void main() {
  test('ofertaGatilhoLabel em PT-BR', () {
    expect(ofertaGatilhoLabel('MANUAL'), 'Manual');
    expect(ofertaGatilhoLabel('checkin'), 'Check-in');
    expect(ofertaGatilhoLabel('TRILHA'), 'Trilha');
    expect(ofertaGatilhoLabel('TRILHA_CONCLUIDA'), 'Trilha');
    expect(ofertaGatilhoLabel(''), 'Manual');
    expect(ofertaGatilhoLabel(null), 'Manual');
    expect(ofertaGatilhoValues, ['MANUAL', 'CHECKIN', 'TRILHA_CONCLUIDA']);
  });

  test('ofertaSubtitle e valor', () {
    expect(
      ofertaSubtitle(tipoGatilho: 'CHECKIN', descricao: 'Pós check-in'),
      'Check-in · Pós check-in',
    );
    expect(ofertaSubtitle(tipoGatilho: 'MANUAL'), 'Manual');
    expect(ofertaValorLabel(199), 'R\$ 199,00');
  });

  test('ofertaStatusLabel e seção', () {
    expect(ofertaStatusLabel(ativo: true), 'Ativa');
    expect(ofertaStatusLabel(ativo: false), 'Pausada');
    expect(ofertaSectionTitle(ativo: true), 'Ativas');
    expect(ofertaSectionTitle(ativo: false), 'Pausadas');
  });

  test('ofertaHubSubtitle junta freshness', () {
    expect(ofertaHubSubtitle(null), 'Ofertas ativas');
    expect(
      ofertaHubSubtitle('há 1 min'),
      'Ofertas ativas · há 1 min',
    );
  });

  test('sticky e sparse hint', () {
    expect(ofertaStickyCtaLabel(), 'Nova oferta');
    expect(ofertaSparseHint(count: 0), isNull);
    expect(ofertaSparseHint(count: 1), contains('Só uma'));
    expect(ofertaSparseHint(count: 2), contains('Poucas ofertas'));
    expect(ofertaSparseHint(count: 3), isNull);
    expect(ofertaListBottomPad(stickyVisible: true), 8);
    expect(ofertaListBottomPad(stickyVisible: false), 24);
  });
}

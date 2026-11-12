import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/utils/oferta_upsell_display.dart';

void main() {
  test('quando mostrar, sem "Gatilho"', () {
    expect(ofertaGatilhoLabel('MANUAL'), 'Só quando eu enviar');
    expect(ofertaGatilhoLabel('CHECKIN'), 'Quando ele bater um recorde');
    expect(
      ofertaGatilhoLabel('TRILHA_CONCLUIDA'),
      'Quando ele concluir uma trilha',
    );
    expect(ofertaGatilhoLabel(null), 'Só quando eu enviar');
  });

  test('resultado da oferta', () {
    expect(ofertaResultadoLabel(enviadas: 0, aceitas: 0), 'Ainda não enviada');
    expect(ofertaResultadoLabel(enviadas: 1, aceitas: 0), 'Enviada 1');
    expect(
      ofertaResultadoLabel(enviadas: 3, aceitas: 1),
      'Enviadas 3 · Aceita 1',
    );
    expect(
      ofertaLinha(
        tipoGatilho: 'CHECKIN',
        enviadas: 3,
        aceitas: 2,
        ativo: false,
      ),
      'Pausada · Quando ele bater um recorde · Enviadas 3 · Aceitas 2',
    );
  });

  test('envio ao aluno', () {
    expect(ofertaEnviarConfirmTitle('Ana'), 'Enviar para Ana?');
    expect(
      ofertaEnviarSuccess(pushEntregue: true),
      'Oferta enviada com notificação',
    );
  });
}

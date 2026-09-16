import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/white_label_display.dart';

void main() {
  test('verify domain só com host e não verificado', () {
    expect(
      whiteLabelCanVerifyDomain(domainDraft: '', dominioVerificado: false),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.studio.com',
        dominioVerificado: true,
      ),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.studio.com',
        dominioVerificado: false,
      ),
      isTrue,
    );
  });

  test('dns steps limpam numeracao do BE', () {
    expect(
      whiteLabelDnsSteps(
        '1) CNAME treino.x.com → cname.focux.app\n'
        '2) TXT _focux.treino.x.com → focux-verify-abc\n'
        '3) Clique em Verificar domínio após propagar DNS (até 24h).',
      ),
      [
        'CNAME treino.x.com → cname.focux.app',
        'TXT _focux.treino.x.com → focux-verify-abc',
        'Clique em Verificar domínio após propagar DNS (até 24h).',
      ],
    );
    expect(whiteLabelCnameHint('treino.x.com'), contains('cname.focux.app'));
  });
}

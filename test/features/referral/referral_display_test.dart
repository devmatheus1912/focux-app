import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/referral/utils/referral_display.dart';

void main() {
  test('referralCodigoLabel e usos', () {
    expect(referralCodigoLabel('ABC12'), 'ABC12');
    expect(referralCodigoLabel('  '), '—');
    expect(referralCodigoLabel(null), '—');
    expect(referralUsosLabel(0), 'Nenhuma ainda');
    expect(referralUsosLabel(1), '1 convertida');
    expect(referralUsosLabel(3), '3 convertidas');
  });

  test('referralInviteText e link', () {
    expect(
      referralInviteText(codigo: 'ABC12', link: 'https://focux.app/cadastro?ref=ABC12'),
      'Use meu código ABC12 e ganhe vantagens no Focux Personal!\nhttps://focux.app/cadastro?ref=ABC12',
    );
    expect(referralTemLink('https://x'), isTrue);
    expect(referralTemLink('  '), isFalse);
    expect(referralTemLink(null), isFalse);
  });

  test('referralHubSubtitle junta freshness', () {
    expect(referralHubSubtitle(null), '30 dias extras no plano');
    expect(
      referralHubSubtitle('Atualizado agora'),
      '30 dias extras no plano · Atualizado agora',
    );
  });

  test('referralHeaderSubtitle junta usos e freshness', () {
    expect(referralHeaderSubtitle(usos: 0, freshness: null), 'Nenhuma ainda');
    expect(
      referralHeaderSubtitle(usos: 2, freshness: 'Atualizado agora'),
      '2 convertidas · Atualizado agora',
    );
  });
}

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/data/plano.dart';
import 'package:focux_app/features/planos/utils/pro_promo_copy.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _pro = Plano(id: 2, nome: 'PRO', precoMensal: 99.9);
const _enterprise = Plano(id: 3, nome: 'ENTERPRISE', precoMensal: 149.5);

void main() {
  final pt = lookupS(const Locale('pt'));

  test('teste termina na data e a conta volta para o Free sem cobrança', () {
    final texto = proPromoTrialFimTexto(pt, DateTime(2026, 10, 28));
    expect(
      texto,
      'O teste termina em 28/10/2026. Depois, sua conta volta para o Free '
      'automaticamente, sem cobrança.',
    );
  });

  test('preço de referência é o do PRO vindo da API; sem preço a linha some', () {
    expect(
      proPromoPrecoPosTesteTexto(pt, const [_pro, _enterprise]),
      'Para continuar no PRO depois do teste: R\$ 99,90/mês',
    );
    expect(proPromoPrecoPosTesteTexto(pt, const [_enterprise]), isNull);
    expect(proPromoPrecoPosTesteTexto(pt, null), isNull);
    expect(
      proPromoPrecoPosTesteTexto(pt, const [
        Plano(id: 2, nome: 'PRO', precoMensal: 0),
      ]),
      isNull,
    );
  });

  test('tela do promo vende o PRO sem fixar preço nem falar de console', () {
    final screen = File(
      'lib/features/planos/screens/pro_promo_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('PRO com \$kTrialDays dias grátis'));
    expect(screen, contains('SubscriptionProducts.proMonthly'));
    expect(screen, contains('kTrialPlan.apiName'));
    expect(screen, contains('Teste do PRO ativado'));
    expect(screen, isNot(contains('Enterprise')));
    expect(screen, isNot(contains('App Store Connect')));
    expect(screen, isNot(contains('Play Console')));
    expect(screen, isNot(contains('R\\\$')));
  });
}

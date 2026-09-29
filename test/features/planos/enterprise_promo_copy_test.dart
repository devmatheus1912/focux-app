import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/data/plano.dart';
import 'package:focux_app/features/planos/utils/enterprise_promo_copy.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _pro = Plano(id: 2, nome: 'PRO', precoMensal: 99.9);
const _enterprise = Plano(id: 3, nome: 'ENTERPRISE', precoMensal: 149.5);

void main() {
  final pt = lookupS(const Locale('pt'));

  test('teste termina na data e a conta volta para o Free sem cobrança', () {
    final texto = enterprisePromoTrialFimTexto(pt, DateTime(2026, 10, 28));
    expect(
      texto,
      'O teste termina em 28/10/2026. Depois, sua conta volta para o Free '
      'automaticamente, sem cobrança.',
    );
    expect(texto, isNot(contains('evitar cobrança')));
  });

  test('preço de referência vem da API; sem preço a linha some', () {
    expect(
      enterprisePromoPrecoPosTesteTexto(pt, const [_pro, _enterprise]),
      'Para continuar no Enterprise depois do teste: R\$ 149,50/mês',
    );
    expect(enterprisePromoPrecoPosTesteTexto(pt, const [_pro]), isNull);
    expect(enterprisePromoPrecoPosTesteTexto(pt, null), isNull);
    expect(
      enterprisePromoPrecoPosTesteTexto(pt, const [
        Plano(id: 3, nome: 'ENTERPRISE', precoMensal: 0),
      ]),
      isNull,
    );
  });

  test('tela do promo não fixa preço nem promete cobrança', () {
    final screen = File(
      'lib/features/planos/screens/enterprise_promo_screen.dart',
    ).readAsStringSync();
    expect(screen, isNot(contains('evitar cobrança')));
    expect(screen, isNot(contains('199,90')));
    expect(screen, isNot(contains('R\\\$')));
  });
}

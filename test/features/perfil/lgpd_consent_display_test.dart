import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/lgpd_consent_repository.dart';
import 'package:focux_app/features/perfil/utils/lgpd_consent_display.dart';

void main() {
  const atual = '2026-09';

  LgpdConsent c(String versao, {String em = '2026-09-10T14:30:00'}) =>
      LgpdConsent(tipo: 'TERMOS', versao: versao, aceitoEm: em);

  test('estado do aceite compara com a versão atual', () {
    expect(lgpdConsentEstado(null, atual), LgpdConsentEstado.pendente);
    expect(lgpdConsentEstado(c('2026-08'), atual), LgpdConsentEstado.versaoAntiga);
    expect(lgpdConsentEstado(c(atual), atual), LgpdConsentEstado.aceito);
  });

  test('resumo e rótulo de aceite', () {
    expect(lgpdConsentResumo(2, 3), 'Falta aceitar 1 documento');
    expect(lgpdConsentResumo(1, 1), 'Tudo aceito');
    expect(lgpdConsentAceitoLabel(c(atual)), 'Aceito em 10/09/2026');
    expect(lgpdConsentAceitoLabel(c(atual, em: '')), 'Aceito');
  });

  test('tipos por perfil', () {
    expect(lgpdConsentTiposPersonal, ['TERMOS', 'PRIVACIDADE']);
    expect(lgpdConsentTiposAluno, ['TERMOS', 'PRIVACIDADE', 'SAUDE']);
  });
}
